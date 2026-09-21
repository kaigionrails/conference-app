Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.configuration.x.github.client_id,
    Rails.configuration.x.github.client_secret,
    {
      client_options: {redirect_uri: Rails.configuration.x.github.oauth_redirect_url},
      origin_param: :return_to
    }

  # Only profile: the display name and the avatar come from it, and the app
  # stores no email, so asking for one would be a permission shown to the user
  # for data that is thrown away.
  provider :google_oauth2,
    Rails.configuration.x.google.client_id,
    Rails.configuration.x.google.client_secret,
    {
      scope: "profile",
      client_options: {redirect_uri: Rails.configuration.x.google.oauth_redirect_url},
      origin_param: :return_to
    }
end
