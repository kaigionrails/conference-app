class Admin::ProfileBadgesProfilesController < AdminController
  # @rbs @profile: Profile
  # @rbs @profile_badges: ProfileBadge::ActiveRecord_Relation

  # @rbs return: void
  def new
    @profile = Profile.preload(:profile_badges).find(params[:profile_id])
    @profile_badges = ProfileBadge.all
  end

  # @rbs return: void
  def create
    @profile = Profile.preload(:profile_badges).find(params[:profile_id])

    given_profile_badge_ids = profile_badges_profiles_params[:profile_badge_ids].reject(&:empty?).map(&:to_i)
    assigned_profile_badge_ids = @profile.profile_badges.map(&:id)
    will_assign_profile_badge_ids = given_profile_badge_ids - assigned_profile_badge_ids
    will_remove_profile_badge_ids = assigned_profile_badge_ids - given_profile_badge_ids

    ApplicationRecord.transaction do
      # rbs_rails types << and destroy as variadic over records, but Active
      # Record takes a relation as well.
      @profile.profile_badges << ProfileBadge.where(id: will_assign_profile_badge_ids) # steep:ignore
      @profile.profile_badges.destroy(ProfileBadge.where(id: will_remove_profile_badge_ids)) # steep:ignore
    end

    redirect_to admin_user_path(id: @profile.user.id)
  end

  private def profile_badges_profiles_params
    params.permit(
      profile_badge_ids: [] # : Array[untyped]
    )
  end
end
