class Admin::SignagesController < AdminController
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

  def new
    @signage = Signage.find_or_initialize_by(event: OngoingEvent.first.event)
  end

  def create
    signage = Signage.find_or_create_by(event: OngoingEvent.first.event)
    signage_schedule = SignageSchedule.new(signage: signage, **zoned_signage_schedule_params)
    if signage.save && signage_schedule.save
      flash.now[:success] = "Signage created"
    else
      flash.now[:error] = "Failed to create signage"
    end
    redirect_to new_admin_signage_path
  end

  def update
    # signage = Signage.find_or_create_by(event: OngoingEvent.first.event)

    zoned_signage_schedule_params
  end

  private def signage_params
    params.require(:signage).permit
  end

  private def signage_schedule_params
    params.require(:signage).require(:signage_schedule).permit(:start_at, :end_at)
  end

  private def zoned_signage_schedule_params
    signage_schedule_params.transform_values { |v| Time.zone.parse(v.gsub("T00:00", "T09:00")) } # convert to JST
  end
end
