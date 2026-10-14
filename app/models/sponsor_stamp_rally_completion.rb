class SponsorStampRallyCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :completed_at, presence: true
  validates :user_id, uniqueness: {scope: :event_id}

  # Serialize awards per user, joining any transaction already held by collection.
  # @rbs user: User
  # @rbs event: Event
  # @rbs return: SponsorStampRallyCompletion?
  def self.award_if_eligible!(user:, event:)
    user.with_lock do
      existing = find_by(user:, event:)
      next existing if existing

      keys = SponsorCatalog.with_booth(event.slug).pluck(:key)
      next if keys.empty?

      visits = user.sponsor_visits.where(event:, sponsor_key: keys)
      next unless visits.count == keys.size

      create!(user:, event:, completed_at: visits.maximum(:created_at))
    end
  end
end
