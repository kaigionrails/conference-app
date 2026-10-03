class ProfileImagesController < ApplicationController
  before_action :require_logged_in

  # @rbs return: void
  def destroy
    image = current_user!.profile.images.find_by(id: params[:id])
    # Not found when it was already deleted from another tab or by a double
    # click, or when it is someone else's: nothing was deleted to report.
    if image
      image.purge
      flash[:success] = t(".succeeded")
    end
    redirect_to edit_profile_path(current_user!.profile)
  end
end
