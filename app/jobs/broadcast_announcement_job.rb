class BroadcastAnnouncementJob < ApplicationJob
  queue_as :default

  def perform(announcement_id)
    # TODO: broadcast announcement
    # Do something later
  end
end
