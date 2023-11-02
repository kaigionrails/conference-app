class ProfileImagesController < ApplicationController
  before_action :require_logged_in

  def destroy
    image = current_user!.profile.images.find_by(id: params[:id])
    image.purge
    flash[:success] = "プロフィール画像を削除しました。"
    redirect_to edit_profile_path(current_user!.profile)
  end
end
