class Profile < ApplicationRecord
  belongs_to :user
  has_many :profile_badges_profiles, dependent: :delete_all
  has_many :profile_badges, through: :profile_badges_profiles

  has_many_attached :images

  # @rbs return: void
  def ensure_image_from_github
    profile_image = fetch_profile_image_from_github
    return if profile_image.nil?

    m = Marcel::Magic.by_magic profile_image
    images.attach(io: profile_image, filename: "github.#{m.subtype}")
  end

  private def fetch_profile_image_from_github
    # Only GitHub registration calls this, so the provider is there; the guard
    # is what lets the type stay nilable for users who arrive another way.
    github = user.authentication_provider_github
    return if github.nil?

    client = Octokit::Client.new
    url = client.user(github.uid.to_i).avatar_url
    URI.open(url) # standard:disable Security/Open
  end
end
