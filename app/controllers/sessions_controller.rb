class SessionsController < ApplicationController
  def new
  end

  def create
    if params[:provider] != "github"
      flash[:alert] = "Unknown provider"
      redirect_to login_path
    end

    user = AuthenticationProviderGithub.find_or_create_user_from_auth_hash(request.env["omniauth.auth"])
    redirect_to root_path
  end

  def destroy
  end
end
