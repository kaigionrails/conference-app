class User < ApplicationRecord
  has_one :authentication_provider_github, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_many :webpush_subscriptions, dependent: :destroy
  has_many :unread_announcements, dependent: :destroy
  has_many :talk_bookmarks, dependent: :destroy
  has_many :profile_exchanges, dependent: :destroy
  has_many :friends, through: :profile_exchanges, class_name: "User"
  has_many :talk_reminders, dependent: :destroy

  enum :role, organizer: "organizer", participant: "participant"

  def have_unread_announcements?
    unread_announcements.exists?
  end
end
