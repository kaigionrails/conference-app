class ProfileBadgesController < ApplicationController
  def new
    unless logged_in?
      redirect_to about_path
      return
    end

    @profile_badge = ProfileBadge.new(restricted: false, text: "サンプル")
  end

  def create
    unless logged_in?
      redirect_to about_path
      return
    end

    profile_badge = ProfileBadge.new(**profile_badge_params, restricted: false)
    if profile_badge.save
      if params[:save_and_assign]
        current_user.profile.profile_badges << profile_badge
      end
      flash.now[:success] = "保存に成功しました"
    else
      flash.now[:alert] = "保存に失敗しました"
    end
    redirect_to new_profile_badge_path
  end

  private def profile_badge_params
    params.require(:profile_badge).permit(:text, :background_color_code, :border_color_code)
  end
end
