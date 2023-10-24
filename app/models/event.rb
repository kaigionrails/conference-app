class Event < ApplicationRecord
  ONGOING_EVENT_SLUG = "2023"

  has_many :talks, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :profile_exchanges
end
