class AuthenticationProviderGithub < AuthenticationProvider
  # @rbs auth: untyped
  # @rbs return: String?
  def self.preferred_handle(auth)
    auth["info"]["nickname"]
  end

  # @rbs auth: untyped
  # @rbs return: String
  def self.display_name_from(auth)
    auth["info"]["nickname"]
  end

  # @rbs user: User
  # @rbs auth: untyped
  # @rbs return: void
  def self.after_create_user(user, auth)
    super
    # Both are GitHub's alone: the organizer role is decided by membership of
    # the kaigionrails org, and the avatar comes from the GitHub account.
    DetermineUserRoleJob.perform_later(user.id)
    user.profile.ensure_image_from(avatar_url_for(user), source: "github")
  end

  # @rbs user: User
  # @rbs return: String?
  private_class_method def self.avatar_url_for(user)
    github = user.authentication_provider_github
    return if github.nil?

    Octokit::Client.new.user(github.uid.to_i).avatar_url
  end
end
