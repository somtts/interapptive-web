class Scene < ActiveRecord::Base
  belongs_to :storybook
  belongs_to :sound

  has_many :keyframes, :dependent => :destroy
  has_many :asset_maps, :as => :assetable,
           :dependent => :destroy
  has_many :images, :through => :asset_maps, :source => :asset,
                    :conditions => { :type => 'Image' },
                    :dependent => :destroy
  has_many :sounds, :through => :asset_maps, :source => :asset,
                    :conditions => { :type => 'Sound' },
                    :dependent => :destroy
  has_many :videos, :through => :asset_maps, :source => :asset,
                    :conditions => { :type => 'Video' },
                    :dependent => :destroy

  has_many :actions, :dependent => :destroy

  # has_many :attributes, :through => :actions

  belongs_to :preview_image, :class_name => 'Image'
  belongs_to :background_sound, :class_name => 'Sound'

  validates_presence_of :storybook, :storybook_id
  validates :position, inclusion: { in: [nil] }, if: :is_main_menu
  validates :is_main_menu, uniqueness: { scope: :storybook_id }, if: :is_main_menu

  serialize :widgets

  before_create :create_main_menu_widgets, if: :is_main_menu
  after_create :create_keyframe

  def as_json(options)
    super.merge({
      :preview_image_url => preview_image.try(:image).try(:url),
      :sound_url         => sound_url
    })
  end

  def can_be_destroyed?
    !is_main_menu
  end

  def sound_url
    if sound.present?
      sound.sound.url
    end
  end

  private

  def create_keyframe
    keyframes.create(position: 0)
  end

  def create_main_menu_widgets
    self.widgets = [
      {type: 'ButtonWidget', id: 1, scale: 1, position: {x:200, y:100}, name: 'read_it_myself', z_order: 4001 },
      {type: 'ButtonWidget', id: 2, scale: 1, position: {x:200, y:200}, name: 'read_to_me',     z_order: 4002 },
      {type: 'ButtonWidget', id: 3, scale: 1, position: {x:200, y:300}, name: 'auto_play',      z_order: 4003 },
    ]
  end



end
