# Base class for the providers a user can sign in through. Each one owns its
# own table, so this is an abstract class rather than STI.
#
# A subclass supplies three things: the handle it would like to give a new
# user, the display name for their profile, and whatever registration has to
# do beyond what every provider shares.
class AuthenticationProvider < ApplicationRecord
  self.abstract_class = true

  # A handle rejected between the availability check and the insert is retried
  # with a freshly generated one. Bounded so that a failure with another cause
  # -- a uid taken by a concurrent callback, say -- surfaces instead of looping.
  CREATE_ATTEMPTS = 3

  belongs_to :user

  # @rbs auth: untyped
  # @rbs return: User
  def self.find_or_create_user_from_auth_hash(auth)
    provider = eager_load(:user).find_by(uid: auth["uid"])
    return provider.user if provider

    create_user_from_auth_hash(auth)
  end

  # @rbs auth: untyped
  # @rbs return: User
  def self.create_user_from_auth_hash(auth)
    attempt = 0
    begin
      attempt += 1
      user = create_user!(handle: handle_for(auth, attempt), display_name: display_name_from(auth), uid: auth["uid"])
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      retry if attempt < CREATE_ATTEMPTS
      raise
    end

    after_create_user(user, auth)
    user
  end

  # The handle the provider would like to use, when it is still available.
  # It may not be: another provider could already hold it, or it could be
  # reserved. Falling back to a generated handle keeps login working for a
  # user who cannot do anything about the clash themselves.
  #
  # @rbs auth: untyped
  # @rbs attempt: Integer
  # @rbs return: String
  private_class_method def self.handle_for(auth, attempt)
    preferred = preferred_handle(auth)
    return User.generate_handle if attempt > 1 || preferred.blank?

    User.new(name: preferred, role: "participant").valid? ? preferred : User.generate_handle
  end

  # @rbs handle: String
  # @rbs display_name: String
  # @rbs uid: String
  # @rbs return: User
  private_class_method def self.create_user!(handle:, display_name:, uid:)
    user = User.new(name: handle, role: "participant")
    # The display name follows the provider even when the handle could not, so
    # a generated handle does not leak into the profile.
    profile = Profile.new(user: user, name: display_name)
    provider = new(uid: uid, user: user)
    ApplicationRecord.transaction do
      user.save!
      provider.save!
      profile.save!
    end
    user
  end

  # Runs once, after a provider has created a brand new user. Subclasses that
  # override this must call super.
  #
  # @rbs user: User
  # @rbs auth: untyped
  # @rbs return: void
  def self.after_create_user(user, auth)
    user.mark_all_announcement_unread!
  end

  # @rbs auth: untyped
  # @rbs return: String?
  def self.preferred_handle(auth)
    raise NotImplementedError, "#{name} must define .preferred_handle"
  end

  # @rbs auth: untyped
  # @rbs return: String
  def self.display_name_from(auth)
    raise NotImplementedError, "#{name} must define .display_name_from"
  end
end
