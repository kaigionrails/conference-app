class User < ApplicationRecord
  has_one :authentication_provider_github, dependent: :destroy
  has_one :authentication_provider_email_and_password, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :locale_setting, dependent: :destroy
  has_many :webpush_subscriptions, dependent: :destroy
  has_many :unread_announcements, dependent: :destroy
  has_many :talk_bookmarks, dependent: :destroy
  has_many :profile_exchanges, dependent: :destroy
  has_many :friends, through: :profile_exchanges, class_name: "User"
  has_many :talk_reminders, dependent: :destroy

  enum :role, {organizer: "organizer", participant: "participant", operator: "operator"}

  # @rbs return: bool
  def have_unread_announcements?
    unread_announcement_count > 0
  end

  def unread_announcement_count
    unread_announcements.joins(:announcement).where(announcement: {event: current_event}).count
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

  # @rbs id: Integer
  # @rbs return: bool
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
