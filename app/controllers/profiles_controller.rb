class ProfilesController < ApplicationController
  before_action :require_logged_in

  def index
    @profile = Profile.preload(:profile_badges).find_by(user: current_user!)
    @friends = current_user!.friends.preload(profile: { images_attachments: :blob })
    @user = User.preload(:friends).find(current_user!.id)
  end

  def new
    @profile = Profile.new(user: current_user!)
    @profile_badges = ProfileBadge.where(restricted: false)
  end

  def edit
    @profile = Profile.find_by(user: current_user!)
    @profile_badges = ProfileBadge.where(restricted: false)
  end

  def create
    profile = Profile.new(user: current_user!, **profile_params)
    if profile.save
      flash[:success] = "プロフィールを保存しました。"
      redirect_to profiles_path
    else
      flash[:alert] = "保存に失敗しました。再度やりなおしてください。"
      redirect_to new_profile_path
    end
  end

  def update
    profile = Profile.preload(:profile_badges).find_by!(user: current_user!)

    given_profile_badge_ids = profile_params[:profile_badge_ids].reject(&:empty?).map(&:to_i)
    assigned_profile_badge_ids = profile.profile_badges.map(&:id)
    will_assign_profile_badge_ids = given_profile_badge_ids - assigned_profile_badge_ids
    will_remove_profile_badge_ids = assigned_profile_badge_ids - given_profile_badge_ids

    ApplicationRecord.transaction do
      profile.update!(**profile_non_image_params)
      profile.images.attach([profile_image_params[:images]]) if profile_image_params[:images].present?
      profile.profile_badges << ProfileBadge.where(restricted: false, id: will_assign_profile_badge_ids)
      profile.profile_badges.destroy(ProfileBadge.where(restricted: false, id: will_remove_profile_badge_ids))
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
    params.require(:profile).permit(:name, :description, images: [], profile_badge_ids: [])
  end

  private def profile_non_image_params
    profile_params.except(:images, :profile_badge_ids)
  end

  private def profile_image_params
    profile_params.slice(:images)
  end
end
