class BroadcastAnnouncementJob < ApplicationJob
  queue_as :default

  def perform(announcement_id)
    announcement = Announcement.find(announcement_id)
    UnreadAnnouncement.insert_all!(
      User.all.ids.map do |user_id|
        {announcement_id: announcement.id, user_id: user_id}
      end
    )
  end
end
