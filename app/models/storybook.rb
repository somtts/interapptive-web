class Storybook < ActiveRecord::Base
  mount_uploader :icon, AppIconUploader
  mount_uploader :compiled_application, IosApplicationUploader
  mount_uploader :android_application,  AndroidApplicationUploader
  mount_uploader :resource_archive,     StorybookResourceArchiveUploader

  belongs_to :user

  has_many :scenes, dependent: :destroy

  has_many :images, dependent: :destroy
  has_many :sounds, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :fonts,  dependent: :destroy
  has_many :assets # a way to refer to all the images, sounds, videos, fonts

  # publishing to the mobile app stores
  has_one :application_information,       dependent: :destroy
  has_one :publish_request,               dependent: :destroy

  # publishing to the subscription (bookfair) platform
  has_one :subscription_publish_request,  dependent: :destroy
  # TODO: waseem: What happens to a SubscriptionStorybook once
  # the original storybook is destroyed?
  has_one :subscription_storybook
  belongs_to :cover_image, class_name: 'Image'

  serialize :widgets

  SETTINGS = {
    pageFlipTransitionDuration: 0.6,
    paragraphTextFadeDuration:  0.4,
    autoplayPageTurnDelay:      0.2,
    autoplayKeyframeDelay:      0.1,
    skipAnimationOnSwipe:       true
  }
  serialize :settings, Hash

  before_validation :set_default_settings, on: :create
  before_create     :create_widgets
  after_create      :create_default_scene

  validates :user, presence: true
  validate  :validate_allowed_storybooks_count, on: :create
  validates :title, presence: true, uniqueness: { scope: :user_id }

  validates :pageFlipTransitionDuration, numericality: { greater_than_or_equal_to: 0 }
  validates :paragraphTextFadeDuration,  numericality: { greater_than_or_equal_to: 0 }
  validates :autoplayPageTurnDelay,      numericality: { greater_than_or_equal_to: 0 }
  validates :autoplayKeyframeDelay,      numericality: { greater_than_or_equal_to: 0 }

  def create_or_update_subscription_publish_request
    spr = SubscriptionPublishRequest.find_or_initialize_by_storybook_id(self.id)
    spr.status = SubscriptionPublishRequest::STATUSES[:review_required]
    spr.save
  end

  def enqueue_for_subscription_publication(json, recipient)
    self.subscription_publish_request.update_attribute(:status, SubscriptionPublishRequest::STATUSES[:ready_to_publish])
    Resque.enqueue(SubscriptionPublicationQueue, self.id, json, recipient.email)
  end

  def enqueue_for_compilation(platform, json, recipient)
    case platform
    when 'ios'
      enqueue_for_ios_compilation(json, recipient)
    when 'android'
      enqueue_for_android_compilation(json, recipient)
    end
  end

  def enqueue_for_ios_compilation(json, recipient)
    Resque.enqueue(IosCompilationQueue, self.id, json, recipient.email)
  end

  def enqueue_for_android_compilation(json, recipient)
    Resque.enqueue(AndroidCompilationQueue, self.id, json, recipient.email)
  end

  def enqueue_for_resource_archiving(json, recipient)
    Resque.enqueue(StorybookResourceArchiveQueue, self.id, json, recipient.email)
  end

  def owned_by?(other_user)
    other_user == user
  end

  def requires_subscription_publication_review?
    subscription_publish_request.present? && subscription_publish_request.review_required?
  end

  def image_id=(image_id)
    image = images.where(id: image_id).first
    if image.present?
      self.icon = image.image
      store_icon!
    else
      remove_icon!
      save
    end
  end

  def all_fonts
    Font.where(asset_type: 'system') + fonts
  end

  SETTINGS.each do |setting, _|
    define_method(setting) do
      settings[setting]
    end

    define_method("#{setting}=") do |value|
      settings[setting] = value
    end
  end

  def publish
    create_publish_request unless publish_request.present?
  end

  def publish_to_subscription
    subscription_publish_request.publish(subscription_storybook)
  end

  def as_json(options={})
    super({
      except: :settings,
      methods: SETTINGS.keys,
      include: [:application_information],
    }.merge(options)).merge({
      preview_image_url: preview_image_url,
      publish_request: publish_request.as_json,
    })
  end

  def preview_image_url
    keyframes = scenes.where(is_main_menu: true).first.keyframes
    first_keyframe = keyframes.where(is_animation: true).first ||
                     keyframes.where(position: 0).first
    first_keyframe.preview_image_url
  end

  private

  def create_default_scene
    scenes.create(is_main_menu: true)
    scenes.create(position: 0)
  end

  def set_default_settings
    SETTINGS.each do |setting, default|
      self.send("#{setting}=", self.send(setting) || default)
    end
  end

  def create_widgets
    # On the client side we need widgets to have unique id's.
    # The home button has id 1. The main menu buttons have id's 2, 3 & 4.
    # `z_order` is in the 4000+ range to leave [1..4000) for sprites,
    # [5000..6000) for hotspots and [6000...) for texts. Main menu buttons have
    # z_order wihtin [4000..4010)
    self.widgets = [
      {type: 'ButtonWidget', id: 1, name: 'home', z_order: 4010, scale: 1, position: {y: 736, x: 36} },
    ]
  end

  def validate_allowed_storybooks_count
    if user.present?
      if user.storybooks.count >= user.allowed_storybooks_count
        errors[:base] << "You are not allowed to create any more storybooks."
      end
    end
  end
end
