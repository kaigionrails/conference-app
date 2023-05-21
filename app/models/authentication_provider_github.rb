class AuthenticationProviderGithub < ApplicationRecord
  belongs_to :user

  def self.find_or_create_user_from_auth_hash(auth)
    authentication_provider_github = AuthenticationProviderGithub.eager_load(:user).find_by(uid: auth.uid)
    return authentication_provider_github.user if authentication_provider_github

    create_user_from_auth_hash(auth)
  end

  def self.create_user_from_auth_hash(auth)
    user = User.new(name: auth["info"]["nickname"], role: "participant")
    auth_provider = AuthenticationProviderGithub.new(uid: auth["uid"], user: user)
    ApplicationRecord.transaction do
      user.save!
      auth_provider.save!
    end
    user
  end
end
