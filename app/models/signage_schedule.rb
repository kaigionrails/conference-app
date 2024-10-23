class SignageSchedule < ApplicationRecord
  belongs_to :signage
  has_many :signage_pages, dependent: :destroy
  has_many :signage_schedule_assigns, dependent: :destroy
end
