class SponsorStampRallyCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :completed_at, presence: true
  validates :user_id, uniqueness: {scope: :event_id}

  # Call inside user.with_lock so concurrent stamp collections serialize.
  # @rbs user: User
  # @rbs event: Event
  # @rbs return: SponsorStampRallyCompletion?
  def self.award_if_eligible!(user:, event:)
    existing = find_by(user:, event:)
    return existing if existing

    keys = SponsorCatalog.with_booth(event.slug).pluck(:key)
    return if keys.empty?

    visits = user.sponsor_visits.where(event:, sponsor_key: keys)
    return unless visits.count == keys.size

    create!(user:, event:, completed_at: visits.maximum(:created_at))
  end
end
