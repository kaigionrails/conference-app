class SessionsController < ApplicationController
  def new
  end

  def create
    case params[:provider]
    when "email"
      if (auth = AuthenticationProviderEmailAndPassword.find_by(email: params[:email]))
        if auth.authenticate(params[:password])
          user = auth.user
        else
          flash[:alert] = "Invalid email or password"
          redirect_to login_path
          return
        end
      else
        flash[:alert] = "Invalid email or password"
        redirect_to login_path
        return
      end
    else
      flash[:alert] = "Unknown provider"
      redirect_to login_path
      return
    end

    session[:user_id] = user.id

    if params.key?("return_to")
      # Prevent open redirect
      uri = URI.parse(params["return_to"])
      redirect_to "#{uri.path}?#{uri.query}"
    else
      redirect_to setting_path
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to about_path
  end
end
