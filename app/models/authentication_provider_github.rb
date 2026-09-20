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
  # @rbs return: void
  def self.after_create_user(user)
    super
    # Both are GitHub's alone: the organizer role is decided by membership of
    # the kaigionrails org, and the avatar comes from the GitHub account.
    DetermineUserRoleJob.perform_later(user.id)
    user.profile.ensure_image_from_github
  end
end
