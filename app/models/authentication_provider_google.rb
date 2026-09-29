class AuthenticationProviderGoogle < AuthenticationProvider
  # Google has no username, so every account gets a generated handle. The base
  # class falls back when this is blank.
  #
  # @rbs auth: untyped
  # @rbs return: String?
  def self.preferred_handle(auth)
    nil
  end

  # Google does not promise a name even with the profile scope, and the strategy
  # drops the key when it is missing, while profiles.name cannot be null. An
  # empty name is the column default, and the user can fill it in later.
  #
  # @rbs auth: untyped
  # @rbs return: String
  def self.display_name_from(auth)
    auth.dig("info", "name").presence || auth.dig("info", "first_name").presence || ""
  end

  # @rbs user: User
  # @rbs auth: untyped
  # @rbs return: void
  def self.after_create_user(user, auth)
    super
    user.profile.ensure_image_from(auth.dig("info", "image"), source: "google")
  end
end
