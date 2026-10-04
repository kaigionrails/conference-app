class Event < ApplicationRecord
  has_many :talks, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :social_announcements, dependent: :destroy
  has_many :profile_exchanges, dependent: :destroy
  has_many :sponsor_visits, dependent: :destroy
  has_many :tito_tickets, dependent: :destroy
  has_one :ongoing_event, dependent: :delete
  has_one :sponsor_booth_qr_card_template, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def ongoing?
    OngoingEvent.first&.event_id == id
  end

  # The number of people who exchanged profiles at this event, not the
  # number of exchanges. Each exchange is stored in both directions, so
  # user_id alone covers everyone.
  #
  # @rbs return: Integer
  def profile_exchange_count
    profile_exchanges.distinct.count(:user_id)
  end
end
