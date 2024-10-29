class Admin::SignageScheduleAssignsController < AdminController
  # @rbs @signage_schedule_assign: SignageScheduleAssign
  # @rbs @signage_schedules: SignageSchedule::ActiveRecord_Relation
  # @rbs @signage_panels: SignagePanel::ActiveRecord_Relation

  # @rbs return: void
  def new
    @signage_schedule_assign = SignageScheduleAssign.new
    @signage_schedules = SignageSchedule.all
    @signage_panels = SignagePanel.all
  end

  # @rbs return: void
  def create
    signage_schedule_assign = SignageScheduleAssign.new(**signage_schedule_assign_params)
    if signage_schedule_assign.save
      flash.now[:success] = "Create signage schedule assign successful"
      redirect_to admin_signages_path
    else
      flash.now[:error] = "Create signage schedule assign failed"
      redirect_to new_admin_signage_schedule_assign_path
    end
  end

  # @rbs return: void
  def destroy
    schedule = SignageScheduleAssign.find(params[:id])
    schedule.destroy
    redirect_to admin_signages_path
  end

  private def signage_schedule_assign_params
    params.require(:signage_schedule_assign).permit(:signage_schedule_id, :signage_panel_id)
  end
end
