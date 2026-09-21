module LoginHelper
  def sign_in(user)
    allow_any_instance_of(SessionsHelper).to receive(:current_user!).and_return(user)
  end

  # Logs in through the GitHub callback, so that the session is established the
  # way it is in production. Use this when what the login itself does to the
  # session is under test; sign_in only stubs the current user.
  def sign_in_through_github(user)
    provider = user.authentication_provider_github ||
      FactoryBot.create(:authentication_provider_github, user: user, uid: "uid-#{user.id}")
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({provider: :github, uid: provider.uid})

    get "/auth/github/callback"
  end
end
