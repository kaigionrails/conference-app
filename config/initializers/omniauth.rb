Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.configuration.x.github.client_id,
    Rails.configuration.x.github.client_secret,
    {
      client_options: {redirect_uri: Rails.configuration.x.github.oauth_redirect_url},
      origin_param: :return_to
    }
end
