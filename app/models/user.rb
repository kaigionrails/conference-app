class User < ApplicationRecord
  has_one :authentication_provider_github, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_many :webpush_subscriptions, dependent: :destroy

  enum :role, organizer: "organizer", participant: "participant"
end
