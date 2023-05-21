class User < ApplicationRecord
  has_one :authentication_provider_github, dependent: :destroy

  enum :role, organizer: "organizer", participant: "participant"
end
