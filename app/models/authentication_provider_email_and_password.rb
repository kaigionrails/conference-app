class AuthenticationProviderEmailAndPassword < ApplicationRecord
  belongs_to :user

  has_secure_password

  # Case-sensitive, matching the unique index. The login lookup is
  # find_by(email:), which is case-sensitive too.
  validates :email, presence: true, uniqueness: true
end
