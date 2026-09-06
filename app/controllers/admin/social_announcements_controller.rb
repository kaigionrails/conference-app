class Admin::SocialAnnouncementsController < AdminController
  include ApplicationHelper

  # @rbs @social_announcements: SocialAnnouncement::ActiveRecord_Relation
  # @rbs @social_announcement: SocialAnnouncement
  # @rbs @events: Event::ActiveRecord_Relation
  # @rbs @event: Event?
  # @rbs @x_token: SocialOauthToken?

  # @rbs return: void
  def index
    @events = Event.order(start_date: :desc)
    @event = params[:event_id].present? ? Event.find(params[:event_id]) : current_event
    scope = @event ? SocialAnnouncement.where(event: @event) : SocialAnnouncement.all
    @social_announcements = scope.includes(:texts, :target_platforms).order(created_at: :desc).page(params[:page]).per(50)
    @x_token = SocialOauthToken.find_by(platform: "x")
  end

  # @rbs return: void
  def show
    @social_announcement = SocialAnnouncement.includes(texts: [:reviews, :posts], target_platforms: [], media: {file_attachment: :blob}).find(params[:id])
    @x_token = SocialOauthToken.find_by(platform: "x")
  end

  # @rbs return: void
  def new
    @social_announcement = SocialAnnouncement.new(event: current_event, created_by: current_user!)
  end

  # @rbs return: void
  def create
    social_announcement = SocialAnnouncement.new(**social_announcement_params, created_by: current_user!)
    if social_announcement.save
      flash[:success] = "Created"
      redirect_to admin_social_announcement_path(social_announcement)
    else
      flash[:alert] = social_announcement.errors.full_messages.join(", ")
      redirect_to new_admin_social_announcement_path
    end
  end

  # @rbs return: void
  def edit
    @social_announcement = SocialAnnouncement.find(params[:id])
  end

  # @rbs return: void
  def update
    social_announcement = SocialAnnouncement.find(params[:id])
    if social_announcement.update(**social_announcement_params)
      flash[:success] = "Update succeeded"
      redirect_to admin_social_announcement_path(social_announcement)
    else
      flash[:alert] = social_announcement.errors.full_messages.join(", ")
      redirect_to edit_admin_social_announcement_path(social_announcement)
    end
  end

  private def social_announcement_params
    params.require(:social_announcement).permit(:event_id, :campaign, :note)
  end
end
