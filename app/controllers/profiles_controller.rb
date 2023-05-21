class ProfilesController < ApplicationController
  before_action :require_logged_in

  def index
    @profile = current_user.profile
  end

  def new
    @profile = Profile.new(user: current_user)
  end

  def edit
    @profile = Profile.find_by(user: current_user)
  end

  def create
    profile = Profile.new(user: current_user, **profile_params)
    if profile.save
      flash[:success] = "プロフィールを保存しました。"
      redirect_to profiles_path
    else
      flash[:alert] = "保存に失敗しました。再度やりなおしてください。"
      redirect_to new_profile_path
    end
  end

  def update
    profile = Profile.find_by(user: current_user)
    if profile.update(**profile_params)
      flash[:success] = "プロフィールを更新しました。"
      redirect_to profiles_path
    else
      flash[:alert] = "更新に失敗しました。再度やりなおしてください。"
      redirect_to edit_profile_path
    end
  end

  private def profile_params
    params.require(:profile).permit(:name, :description, images: [])
  end
end
