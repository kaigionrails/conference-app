class SessionsController < ApplicationController
  def new
  end

  def create
    if params[:provider] != "github"
      flash[:alert] = "Unknown provider"
      redirect_to login_path
      return
    end

    user = AuthenticationProviderGithub.find_or_create_user_from_auth_hash(request.env["omniauth.auth"])
    session[:user_id] = user.id

    if request.env["omniauth.params"].key?("return_to")
      # Prevent open redirect
      uri = URI.parse(request.env["omniauth.params"]["return_to"])
      redirect_to "#{uri.path}?#{uri.query}"
    else
      redirect_to root_path
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to about_path
  end
end
