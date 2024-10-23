class Admin::SignageSchedulesController < AdminController
  def new
    @signage = Signage.find_or_initialize_by(event: OngoingEvent.first.event)
    @signage_schedule = SignageSchedule.new(signage: @signage)
  end

  def create
    signage = Signage.find_or_create_by(event: OngoingEvent.first.event)
    signage_schedule = SignageSchedule.new(signage: signage, **zoned_signage_schedule_params)
    if signage.save && signage_schedule.save
      flash.now[:success] = "Signage schedule created"
    else
      flash.now[:error] = "Failed to create signage schedule"
    end
    redirect_to admin_signages_path
  end

  def edit
    @signage_schedule = SignageSchedule.find(params[:id])
  end

  def update
    schedule = SignageSchedule.find(params[:id])
    binding.irb
    if schedule.update(**zoned_signage_schedule_params)
      flash.now[:success] = "Signage schedule updated"
    else
      flash.now[:error] = "Failed to update signage schedule"
    end
    redirect_to admin_signages_path
  end

  def destroy
    schedule = SignageSchedule.find(params[:id])
    schedule.destroy
    redirect_to admin_signages_path
  end

  private def signage_schedule_params
    params.require(:signage_schedule).permit(:start_at, :end_at)
  end

  private def zoned_signage_schedule_params
    signage_schedule_params.transform_values { |v| Time.zone.parse("#{v} +09:00") } # convert to JST
  end
end
