class Profile < ApplicationRecord
  belongs_to :user
  has_many :profile_badges_profiles, dependent: :delete_all
  has_many :profile_badges, through: :profile_badges_profiles

  has_many_attached :images

  # The provider passes the URL: it is the one that knows where its avatars
  # live, and this way Profile does not reach back into a provider of its own.
  #
  # @rbs url: String?
  # @rbs source: String
  # @rbs return: void
  def ensure_image_from(url, source:)
    return if url.blank?

    profile_image = URI.open(url) # standard:disable Security/Open
    m = Marcel::Magic.by_magic profile_image
    images.attach(io: profile_image, filename: "#{source}.#{m.subtype}")
  end
end
