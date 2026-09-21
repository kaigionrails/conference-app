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
          reject_login
          return
        end
      else
        reject_login
        return
      end
    else
      flash[:alert] = t("sessions.create.unknown_provider")
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

  # The same message whether or not the email exists, so the form does not
  # confirm which addresses are registered.
  #
  # @rbs return: void
  private def reject_login
    flash[:alert] = t("sessions.create.invalid_email_or_password")
    redirect_to login_path
  end
end
