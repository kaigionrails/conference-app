class Admin::AnnouncementsController < AdminController
  def index
    @announcements = Announcement.all.page(params[:page]).per(50)
  end

  def show
    @announcement = Announcement.find(params[:id])
  end

  def new
    event = Event.find_by!(slug: Event::ONGOING_EVENT_SLUG)
    @announcement = Announcement.new(event: event)
  end

  def create
    Announcement.create!(**announcement_params)
    redirect_to admin_announcements_path
  end

  private def announcement_params
    params.require(:announcement).permit(:event_id, :title, :content, :status)
  end
end
