class Admin::SocialAnnouncementDispatchesController < AdminController
  # @rbs return: void
  def create
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    begin
      announcement.dispatch_all_posts!
      flash[:success] = "Posts enqueued"
    rescue Social::PostError => e
      flash[:alert] = "Dispatch failed: #{e.message}"
    end
    redirect_to admin_social_announcement_path(announcement)
  end
end
