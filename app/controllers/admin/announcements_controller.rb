class Admin::AnnouncementsController < AdminController
  # @rbs @announcements: Announcement::ActiveRecord_Relation
  # @rbs @announcement: Announcement

  # @rbs return: void
  def index
    @announcements = Announcement.all.order(created_at: :desc).page(params[:page]).per(50)
  end

  # @rbs return: void
  def show
    @announcement = Announcement.find(params[:id])
  end

  # @rbs return: void
  def new
    event = Event.find_by!(slug: Event::ONGOING_EVENT_SLUG)
    @announcement = Announcement.new(event: event)
  end

  # @rbs return: void
  def create
    Announcement.create!(**announcement_params)
    redirect_to admin_announcements_path
  end

  # @rbs return: void
  def edit
    @announcement = Announcement.find(params[:id])
  end

  # @rbs return: void
  def update
    announcement = Announcement.find(params[:id])
    if announcement.update(**announcement_params)
      flash[:success] = "Update succeeded"
      if announcement.previous_changes.has_key?("status") && announcement.previous_changes["status"] == ["draft", "published"]
        BroadcastAnnouncementJob.perform_later(announcement.id)
        SendAnnouncementPushNotificationJob.perform_later(announcement.id, push_notification_message(announcement))
      end
      redirect_to admin_announcement_path(announcement)
    else
      flash[:alert] = "Update failed"
      redirect_to edit_admin_announcement_path(announcement)
    end
  end

  private def announcement_params
    params.require(:announcement).permit(:event_id, :title, :content, :status)
  end

  # @rbs announcement: Announcement
  # @rbs return: Hash[untyped, untyped]
  private def push_notification_message(announcement)
    {
      title: t(".new_announcement_created"),
      body: announcement.title,
      icon: view_context.image_url("icons/2024/512.png"),
      data: {
        url: event_announcement_url(
          event_slug: announcement.event.slug,
          id: announcement.id,
          host: Rails.configuration.application_url
        )
      }
    }
  end
end
