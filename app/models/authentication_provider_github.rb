class AuthenticationProviderGithub < ApplicationRecord
  # A handle rejected between the availability check and the insert is retried
  # with a freshly generated one. Bounded so that a failure with another cause
  # -- a uid taken by a concurrent callback, say -- surfaces instead of looping.
  CREATE_ATTEMPTS = 3

  belongs_to :user

  # @rbs auth: untyped
  # @rbs &block: ?(User) -> untyped
  # @rbs return: User
  def self.find_or_create_user_from_auth_hash(auth, &)
    authentication_provider_github = AuthenticationProviderGithub.eager_load(:user).find_by(uid: auth["uid"])
    return authentication_provider_github.user if authentication_provider_github

    create_user_from_auth_hash(auth, &)
  end

  # @rbs auth: untyped
  # @rbs &block: ?(User) -> untyped
  # @rbs return: User
  def self.create_user_from_auth_hash(auth, &block)
    nickname = auth["info"]["nickname"]
    uid = auth["uid"]

    attempt = 0
    begin
      attempt += 1
      # The GitHub username is the handle when it is still available. It may
      # not be: another provider could already hold it, or it could be
      # reserved. Fall back to a generated handle so that login still succeeds
      # for a user who cannot do anything about the clash.
      handle = if attempt == 1 && User.new(name: nickname, role: "participant").valid?
        nickname
      else
        User.generate_handle
      end
      user = create_user!(handle: handle, display_name: nickname, uid: uid)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      retry if attempt < CREATE_ATTEMPTS
      raise
    end

    yield(user) if block
    user
  end

  # @rbs handle: String
  # @rbs display_name: String
  # @rbs uid: String
  # @rbs return: User
  private_class_method def self.create_user!(handle:, display_name:, uid:)
    user = User.new(name: handle, role: "participant")
    # The display name follows GitHub even when the handle could not, so a
    # generated handle does not leak into the profile.
    profile = Profile.new(user: user, name: display_name)
    auth_provider = new(uid: uid, user: user)
    ApplicationRecord.transaction do
      user.save!
      auth_provider.save!
      profile.save!
    end
    user
  end
end
