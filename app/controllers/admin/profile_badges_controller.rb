class Admin::ProfileBadgesController < AdminController
  def index
    @profile_badges = ProfileBadge.all
  end

  def new
    @profile_badge = ProfileBadge.new
  end

  def edit
    @profile_badge = ProfileBadge.find(params[:id])
  end

  def create
    profile_badge = ProfileBadge.new(**profile_badge_params)
    if profile_badge.save
      redirect_to admin_profile_badges_path
    else
      redirect_to new_admin_profile_badge_path
    end

  end

  def update
    @profile_badge = ProfileBadge.find(params[:id])
    @profile_badge.update!(**profile_badge_params)
    redirect_to admin_profile_badges_path
  end

  def destroy
    @profile_badge = ProfileBadge.find(params[:id])
    @profile_badge.destroy!
    redirect_to admin_profile_badges_path
  end

  private def profile_badge_params
    params.require(:profile_badge).permit(:text, :border_color_code, :background_color_code, :restricted)
  end
end
