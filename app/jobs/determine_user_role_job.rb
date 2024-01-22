class DetermineUserRoleJob < ApplicationJob
  queue_as :default

  discard_on(Octokit::Error) do |_job, error|
    Sentry.capture_exception(error)
  end

  def perform(user_id)
    user = User.find(user_id)

    # https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
    app_client = Octokit::Client.new(bearer_token: github_jwt)
    installation_id = app_client.find_organization_installation("kaigionrails")[:id]
    access_token = app_client.create_app_installation_access_token(installation_id)
    org_client = Octokit::Client.new(access_token: access_token[:token])
    github_user = Octokit.user(user.authentication_provider_github.uid.to_i)

    if org_client.organization_member?("kaigionrails", github_user[:login])
      user.update!(role: :organizer)
    end
  end

  def github_jwt
    payload = {
      iat: Time.now.to_i,
      exp: Time.now.to_i + (10 * 60),
      iss: Rails.configuration.x.github.app_id
    }
    pem = Rails.configuration.x.github.private_key.unpack1("m*") # : String
    JWT.encode(payload, OpenSSL::PKey::RSA.new(pem, ""), "RS256")
  end
end
