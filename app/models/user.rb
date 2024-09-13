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
    unread_announcements.joins(:announcement).where(announcement: { event: current_event }).exists?
  end

  def mark_all_announcement_unread!(event = nil)
    event ||= current_event
    insert_ary = Announcement.published.where(event: event).ids.map do |ann_id|
      {announcement_id: ann_id, user_id: id}
    end
    UnreadAnnouncement.insert_all!(insert_ary) unless insert_ary.empty?
  end

  def send_push_notification(message)
    webpush_subscriptions.each do |subscription|
      subscription.send_webpush!(message)
    rescue WebPush::ExpiredSubscription
      subscription.destroy!
      next
    end
  end

  def destroy_talk_bookmark_with_reminder!(id)
    talk_bookmark = talk_bookmarks.find(id)

    talk = talk_bookmark.talk
    transaction do
      talk_bookmark.destroy!
      talk_reminders.find_by(talk: talk)&.destroy!
    end
    true
  end
end
