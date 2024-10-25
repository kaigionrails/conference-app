class Admin::SignagePagesController < AdminController
  def index
    @signage_pages = SignagePage.all
  end

  def new
    @signage_schedules = SignageSchedule.all
    @signage_page = SignagePage.new
  end

  def create
    signage_page = SignagePage.new(signage_page_params)
    if signage_page.save
      redirect_to admin_signages_path
    end
  end

  def update
  end

  def destroy
    signage_page = SignagePage.find(params[:id])
    if signage_page.destroy
      redirect_to admin_signages_path
    end
  end

  private def signage_page_params
    params.require(:signage_page).permit(:signage_schedule_id, :order, :duration_second, :page_image)
  end
end
