
class AuthenticationProviderGithub < ApplicationRecord
  def self.find_or_create_user_from_auth_hash: (untyped auth) -> untyped

  def self.create_user_from_auth_hash: (untyped auth) -> untyped
end
