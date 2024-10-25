class Admin::SignagesController < AdminController
  def index
    @signages = Signage.preload(
      signage_schedules: [
        {signage_pages: {page_image_attachment: :blob}},
        {signage_schedule_assigns: :signage_panel}
      ] # steep:ignore
    ).all
    @signage_panels = SignagePanel.all
    @signage_devices = SignageDevice.all
  end

  def new
    @signage = Signage.find_or_initialize_by(event: OngoingEvent.first.event)
  end

  def create
    _signage = Signage.find_or_create_by(event: OngoingEvent.first.event)
    redirect_to admin_signages_path
  end

  def update
  end

  private def signage_params
    params.require(:signage).permit
  end
end
