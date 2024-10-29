class AnnouncementsController < ApplicationController
  # @rbs @event: Event
  # @rbs @announcements: Announcement::ActiveRecord_Relation
  # @rbs @unread_announcements: UnreadAnnouncement::ActiveRecord_Associations_CollectionProxy | UnreadAnnouncement::ActiveRecord_Relation
  # @rbs @announcement: Announcement
  # @rbs @unread_announcement: UnreadAnnouncement?

  def index
    @event = Event.find_by!(slug: params[:event_slug])
    @announcements = Announcement.where(event: @event).published.order(id: :desc, published_at: :desc)
    @unread_announcements = logged_in? ? current_user!.unread_announcements : UnreadAnnouncement.none
  end

  def show
    @event = Event.find_by!(slug: params[:event_slug])
    @announcement = Announcement.where(event: @event).published.with_rich_text_content_and_embeds.find(params[:id])
    @unread_announcement = logged_in? ? current_user!.unread_announcements.find_by(announcement: @announcement) : nil
  end
end
