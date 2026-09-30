class AuthCallbackController < ApplicationController
  PROVIDERS = {
    "github" => AuthenticationProviderGithub,
    "google_oauth2" => AuthenticationProviderGoogle
  }.freeze

  # @rbs return: void
  def create
    provider = PROVIDERS[params[:provider]]
    if provider.nil?
      flash[:alert] = t("auth_callback.create.unknown_provider")
      redirect_to login_path
      return
    end

    # OmniAuth leaves this unset when the callback is reached without a
    # successful auth phase, which used to be caught by the github-only guard.
    auth = request.env["omniauth.auth"]
    if auth.nil?
      flash[:alert] = t("auth_callback.create.failed")
      redirect_to login_path
      return
    end

    user = provider.find_or_create_user_from_auth_hash(auth)
    complete_login!(user)

    omniauth_params = request.env["omniauth.params"] || {}
    redirect_to safe_return_to(omniauth_params["return_to"], default: setting_path)
  end
end
