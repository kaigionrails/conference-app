class Admin::SocialAnnouncementTextReviewsController < AdminController
  # @rbs return: void
  def create
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    text = announcement.texts.find(params[:social_announcement_text_id])
    SocialAnnouncementTextReview.create_for!(text, reviewer: current_user!)
    flash[:success] = "Text (#{text.locale}) reviewed"
    redirect_to admin_social_announcement_path(announcement)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    flash[:alert] = "Review failed: #{e.message}"
    redirect_to admin_social_announcement_path(announcement)
  end
end
