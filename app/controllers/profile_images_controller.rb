class ProfileImagesController < ApplicationController
  before_action :require_logged_in

  # @rbs return: void
  def destroy
    image = current_user!.profile.images.find_by(id: params[:id])
    image&.purge
    flash[:success] = t(".succeeded")
    redirect_to edit_profile_path(current_user!.profile)
  end
end
