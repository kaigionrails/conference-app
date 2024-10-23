class Admin::SignageSchedulesController < AdminController
  def edit
  end

  def update
  end

  def destroy
    schedule = SignageSchedule.find(params[:id])
    schedule.destroy
  end
end
