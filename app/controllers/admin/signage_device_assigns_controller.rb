class Admin::SignageDeviceAssignsController < AdminController
  def new
    @signage_device_assign = SignageDeviceAssign.new
    @signage_devices = SignageDevice.all
    @signage_panels = SignagePanel.all
  end

  def create
    signage_device_assign = SignageDeviceAssign.new(**signage_device_assign_params)
    if signage_device_assign.save
      flash.now[:success] = "Create signage device assign successful"
      redirect_to admin_signages_path
    else
      flash.now[:error] = "Create signage device assign failed"
      redirect_to new_admin_signage_device_assign_path
    end
  end

  def destroy
    signage_devive_assign = SignageDeviceAssign.find(params[:id])
    signage_devive_assign.destroy
    redirect_to admin_signages_path
  end

  private def signage_device_assign_params
    params.require(:signage_device_assign).permit(:signage_device_id, :signage_panel_id)
  end
end
