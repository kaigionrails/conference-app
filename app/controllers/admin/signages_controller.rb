class Admin::SignagesController < AdminController
  # @rbs @signages: Signage::ActiveRecord_Relation
  # @rbs @signage_panels: SignagePanel::ActiveRecord_Relation
  # @rbs @signage_devices: SignageDevice::ActiveRecord_Relation
  # @rbs @signage: Signage

  # @rbs return: void
  def index
    @signages = Signage.preload(
      signage_schedules: [
        {signage_pages: {page_image_attachment: :blob}},
        {signage_schedule_assigns: :signage_panel}
      ]
    ).all
    @signage_panels = SignagePanel.all
    @signage_devices = SignageDevice.all
  end

  # @rbs return: void
  def new
    @signage = Signage.find_or_initialize_by(event: OngoingEvent.first.event)
  end

  # @rbs return: void
  def create
    _signage = Signage.find_or_create_by(event: OngoingEvent.first.event)
    redirect_to admin_signages_path
  end

  # @rbs return: void
  def update
  end

  private def signage_params
    params.require(:signage).permit
  end
end
