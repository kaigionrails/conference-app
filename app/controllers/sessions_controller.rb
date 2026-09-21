class SessionsController < ApplicationController
  before_action :reject_when_login_attempts_exceeded, only: :create

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

    clear_failed_logins!
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
    count_failed_login!
    flash[:alert] = t("sessions.create.invalid_email_or_password")
    redirect_to login_path
  end

  # @rbs return: void
  private def reject_when_login_attempts_exceeded
    return unless login_attempts_exceeded?

    flash[:alert] = t("sessions.create.rate_limited")
    redirect_to login_path
  end
end
