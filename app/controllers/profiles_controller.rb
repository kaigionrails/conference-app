class ProfilesController < ApplicationController
  before_action :require_logged_in

  def index
    @profile = current_user.profile
    @friends = current_user.friends.preload(profile: { images_attachments: :blob })
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
    ApplicationRecord.transaction do
      profile.update!(**profile_non_image_params)
      profile_image_params[:images]&.each do |image|
        profile.images.attach(image)
      end
    end
    if profile
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

  private def profile_non_image_params
    profile_params.except(:images)
  end

  private def profile_image_params
    profile_params.slice(:images)
  end
end
