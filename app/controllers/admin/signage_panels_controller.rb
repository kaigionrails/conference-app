class Admin::SignagePanelsController < AdminController
  def new
    @signage_panel = SignagePanel.new
  end

  def edit
    @signage_panel = SignagePanel.find(params[:id])
  end

  def create
    signage_panel = SignagePanel.new(**signage_panel_params)
    if signage_panel.save
      flash.now[:success] = "Create signage panel successful"
      redirect_to admin_signages_path
    else
      flash.now[:error] = "Create signage panel failed"
      redirect_to new_admin_signage_panel_path
    end
  end

  def update
    signage_panel = SignagePanel.find(params[:id])
    if signage_panel.update(**signage_panel_params)
      flash.now[:success] = "Update signage panel successful"
      redirect_to admin_signages_path
    else
      flash.now[:error] = "Update signage panel failed"
      redirect_to new_admin_signage_panel_path
    end
  end

  private def signage_panel_params
    params.require(:signage_panel).permit(:name)
  end
end
