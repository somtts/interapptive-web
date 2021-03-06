class PublishRequest < ActiveRecord::Base
  belongs_to :storybook
  has_many :applications, dependent: :destroy
  accepts_nested_attributes_for :applications, reject_if: proc { |attributes| attributes['url'].blank? }

  def done?
    applications_count < Application::PROVIDERS.keys.count
  end

  def as_json(options={})
    super({
      include: :applications,
    }.merge(options))
  end
end
