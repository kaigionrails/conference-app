class Signage < ApplicationRecord
  belongs_to :event
  has_many :signage_schedules, dependent: :destroy
end
