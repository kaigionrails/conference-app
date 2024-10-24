class SignagePanel < ApplicationRecord
  has_many :signage_device_assigns, dependent: :destroy
  has_many :signage_schedule_assigns, dependent: :destroy

  has_many :signage_schedules, through: :signage_schedule_assigns
end
