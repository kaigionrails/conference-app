class AuthCallbackController < ApplicationController
  PROVIDERS = {"github" => AuthenticationProviderGithub}.freeze

  # @rbs return: void
  def create
    provider = PROVIDERS[params[:provider]]
    if provider.nil?
      flash[:alert] = "Unknown provider"
      redirect_to login_path
      return
    end

    # OmniAuth leaves this unset when the callback is reached without a
    # successful auth phase, which used to be caught by the github-only guard.
    auth = request.env["omniauth.auth"]
    if auth.nil?
      flash[:alert] = "Authentication failed"
      redirect_to login_path
      return
    end

    user = provider.find_or_create_user_from_auth_hash(auth)

    reset_session
    session[:user_id] = user.id

    if request.env["omniauth.params"].key?("return_to")
      # Prevent open redirect
      uri = URI.parse(request.env["omniauth.params"]["return_to"])
      redirect_to "#{uri.path}?#{uri.query}"
    else
      redirect_to setting_path
    end
  end
end
