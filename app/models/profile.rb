class Profile < ApplicationRecord
  belongs_to :user
  has_many :profile_badges_profiles, dependent: :destroy
  has_many :profile_badges, through: :profile_badges_profiles

  has_many_attached :images

  # @rbs return: void
  def ensure_image_from_github
    profile_image = fetch_profile_image_from_github
    m = Marcel::Magic.by_magic profile_image
    images.attach(io: profile_image, filename: "github.#{m.subtype}")
  end

  private def fetch_profile_image_from_github
    client = Octokit::Client.new
    url = client.user(user.authentication_provider_github.uid.to_i).avatar_url
    URI.open(url) # standard:disable Security/Open
  end
end
