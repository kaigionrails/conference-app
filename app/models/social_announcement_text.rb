class SocialAnnouncementText < ApplicationRecord
  belongs_to :social_announcement
  has_many :reviews, class_name: "SocialAnnouncementTextReview", dependent: :destroy
  has_many :posts, class_name: "SocialAnnouncementPost", dependent: :destroy
  before_destroy :prevent_standalone_destroy_if_posted, prepend: true

  validates :locale, inclusion: {in: SocialAnnouncement::LOCALES}
  validates :locale, uniqueness: {scope: :social_announcement_id}
  validates :body, presence: true
  validate :body_within_strictest_platform_limit
  after_commit :sync_parent_published_at

  # 現在の本文かつ現在のメディアセットに対する、本文の最終更新以降のレビューが存在するか。
  # 本文またはメディアを変えると digest がずれ、未レビューに戻る。過去にレビューされた版へ
  # 戻した場合も、古いレビューは数えず再レビューを要求する。
  # @rbs return: bool
  def approved?
    current_reviews.exists?
  end

  # @rbs return: SocialAnnouncementTextReview?
  def latest_review
    current_reviews.order(reviewed_at: :desc).first
  end

  # @rbs return: String
  def current_body_digest
    Digest::SHA256.hexdigest(body.to_s)
  end

  private def current_reviews
    reviews.where(
      body_digest: current_body_digest,
      media_digest: social_announcement.current_media_digest,
      reviewed_at: updated_at..
    )
  end

  private def sync_parent_published_at
    social_announcement&.sync_published_at!
  end

  # Event / SocialAnnouncement からの cascade では Post も消す。
  # Admin から Text だけ消そうとしたときは投稿記録を守る。
  private def prevent_standalone_destroy_if_posted
    return if destroyed_by_association
    return if posts.none?

    errors.add(:base, "cannot delete text that already has posts")
    throw :abort
  end

  # X の weighted 280 を全プラットフォーム共通の上限にする。
  private def body_within_strictest_platform_limit
    return if Social::XWeightedLength.new(body).valid?

    errors.add(:body, "exceeds #{Social::XWeightedLength::LIMIT} weighted chars (X limit)")
  end
end
