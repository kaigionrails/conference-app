class SessionsController < ApplicationController
  # @rbs return: void
  def new
  end

  # @rbs return: void
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

    complete_login!(user)
    redirect_to safe_return_to(params[:return_to], default: operators_path)
  end

  # @rbs return: void
  def destroy
    reset_session
    redirect_to about_path
  end
end
