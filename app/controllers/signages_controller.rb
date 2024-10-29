class SignagesController < ApplicationController
  layout "signage"

  # @rbs return: void
  def index
    redirect_to login_path unless logged_in?
    redirect_to about_path if current_user!.participant?

    respond_to do |format|
      format.html {}
      format.json do
        signage_device = SignageDevice.preload(
          signage_device_assigns: {
            signage_panel: {
              signage_schedules: [
                :signage_schedule_assigns,
                {signage_pages: {page_image_attachment: :blob}}
              ]
            }
          }
        ).find_by(id: params[:device_id])
        render json: SignageDeviceResource.new(signage_device).serialize
      end
    end
  end
end
