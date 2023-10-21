class Admin::AnnouncementsController < AdminController
  def index
    @announcements = Announcement.all
  end

  def show
    @announcement = Announcement.find(params[:id])
  end
end
