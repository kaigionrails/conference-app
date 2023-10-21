Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_KEY"], ENV["GITHUB_SECRET"], {
    client_options: { redirect_uri: ENV["GITHUB_OAUTH_REDIRECT_URI"] }
  }
end
