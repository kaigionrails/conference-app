class ProfilesController < ApplicationController
  before_action :require_logged_in

  # @rbs @profile: Profile
  # @rbs @events: Event::ActiveRecord_Relation
  # @rbs @event_friends: untyped
  # @rbs @user: User
  # @rbs @profile_badges: ProfileBadge::ActiveRecord_Relation

  # @rbs return: void
  def index
    @profile = Profile.preload(:profile_badges).find_by!(user: current_user!)
    @events = Event.all.order(start_date: :desc)
    @event_friends = current_user!.profile_exchanges.preload(:event, friend: {profile: {images_attachments: :blob}}).group_by(&:event)

    @user = User.preload(:friends).find(current_user!.id)
  end

  def edit
    @profile = Profile.find_by!(user: current_user!)
    @profile_badges = ProfileBadge.where(restricted: false)
  end

  def update
    profile = Profile.preload(:profile_badges).find_by!(user: current_user!)

    given_profile_badge_ids = profile_params[:profile_badge_ids].reject(&:empty?).map(&:to_i)
    assigned_profile_badge_ids = profile.profile_badges.map(&:id)
    will_assign_profile_badge_ids = given_profile_badge_ids - assigned_profile_badge_ids
    will_remove_profile_badge_ids = assigned_profile_badge_ids - given_profile_badge_ids

    begin
      ApplicationRecord.transaction do
        profile.update!(**profile_non_image_params)
        profile.images.attach([profile_image_params[:images]]) if profile_image_params[:images].present?
        profile.profile_badges << ProfileBadge.where(restricted: false, id: will_assign_profile_badge_ids)
        profile.profile_badges.destroy(ProfileBadge.where(restricted: false, id: will_remove_profile_badge_ids))
      end
      flash[:success] = "プロフィールを更新しました。"
      redirect_to profiles_path
    rescue
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
