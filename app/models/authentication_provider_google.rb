class AuthenticationProviderGoogle < AuthenticationProvider
  # Google has no username, so every account gets a generated handle. The base
  # class falls back when this is blank.
  #
  # @rbs auth: untyped
  # @rbs return: String?
  def self.preferred_handle(auth)
    nil
  end

  # @rbs auth: untyped
  # @rbs return: String
  def self.display_name_from(auth)
    auth["info"]["name"]
  end

  # @rbs user: User
  # @rbs auth: untyped
  # @rbs return: void
  def self.after_create_user(user, auth)
    super
    user.profile.ensure_image_from(auth["info"]["image"], source: "google")
  end
end
