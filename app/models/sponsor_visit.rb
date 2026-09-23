class SponsorVisit < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :sponsor_key, presence: true, uniqueness: {scope: [:user_id, :event_id]}
end
