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

  def mark_all_announcement_unread!(event = nil)
    event ||= Event.find_by!(slug: Event::ONGOING_EVENT_SLUG)
    insert_ary = Announcement.published.where(event: event).pluck(:id).map do |ann_id|
      {announcement_id: ann_id, user_id: id}
    end
    UnreadAnnouncement.insert_all!(insert_ary) unless insert_ary.empty?
  end

  def send_push_notification(message)
    webpush_subscriptions.each do |subscription|
      subscription.send_webpush!(message)
    rescue WebPush::ExpiredSubscription
      subscription.destroy
      next
    end
  end
end
