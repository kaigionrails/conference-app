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
    # Nothing saves a user again after creating them, so this tells the
    # callback that created the user apart from every later login.
    first_login = user.previously_new_record?
    complete_login!(user)

    omniauth_params = request.env["omniauth.params"] || {}
    # A first login lands on the profile form, unless it was on its way
    # somewhere: a stamp scanned before logging in still gets collected.
    default = first_login ? edit_profile_path(user.profile) : setting_path
    destination = safe_return_to(omniauth_params["return_to"], default:)
    # Set after complete_login!, whose reset_session clears the flash too.
    if first_login
      flash[:notice] = if destination == default
        t("auth_callback.create.fill_in_your_profile")
      else
        # The page they land on has no link to the form, so say where it is.
        t("auth_callback.create.fill_in_your_profile_from_menu")
      end
    end
    redirect_to destination
  end
end
