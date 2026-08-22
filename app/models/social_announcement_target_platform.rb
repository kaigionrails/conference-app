class SocialAnnouncementTargetPlatform < ApplicationRecord
  belongs_to :social_announcement
  has_many :posts, class_name: "SocialAnnouncementPost", dependent: :destroy
  before_destroy :prevent_standalone_destroy_if_posted, prepend: true

  validates :platform, inclusion: {in: SocialAnnouncement::PLATFORMS}
  validates :platform, uniqueness: {scope: :social_announcement_id}

  after_commit :sync_parent_published_at

  private def sync_parent_published_at
    social_announcement&.sync_published_at!
  end

  private def prevent_standalone_destroy_if_posted
    return if destroyed_by_association
    return if posts.none?

    errors.add(:base, "cannot delete target platform that already has posts")
    throw :abort
  end
end
