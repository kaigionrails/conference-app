class AuthenticationProviderGithub < ApplicationRecord
  belongs_to :user

  def self.find_or_create_user_from_auth_hash(auth, &block)
    authentication_provider_github = AuthenticationProviderGithub.eager_load(:user).find_by(uid: auth.uid)
    return authentication_provider_github.user if authentication_provider_github

    if block_given?
      create_user_from_auth_hash(auth, &block)
    else
      create_user_from_auth_hash(auth)
    end
  end

  def self.create_user_from_auth_hash(auth)
    user = User.new(name: auth["info"]["nickname"], role: "participant")
    profile = Profile.new(user: user, name: user.name)
    auth_provider = AuthenticationProviderGithub.new(uid: auth["uid"], user: user)
    ApplicationRecord.transaction do
      user.save!
      auth_provider.save!
      profile.save!
    end
    yield(user) if block_given?
    user
  end
end
