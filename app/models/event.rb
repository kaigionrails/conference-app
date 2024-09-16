class Event < ApplicationRecord
  ONGOING_EVENT_SLUG = "2024" # FIXME: Remove this const

  has_many :talks, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :profile_exchanges, dependent: :destroy
  has_one :ongoing_event, dependent: :delete

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def ongoing?
    OngoingEvent.first&.event_id == id
  end
end
