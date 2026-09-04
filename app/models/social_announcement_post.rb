class SocialAnnouncementPost < ApplicationRecord
  belongs_to :social_announcement_text
  belongs_to :social_announcement_target_platform
  has_one :social_announcement, through: :social_announcement_text

  # posting はジョブが投稿権を取って外部 API を呼んでいる間の状態
  enum :status, {pending: "pending", posting: "posting", succeeded: "succeeded", failed: "failed"}
  # ジョブがこの時間を超えて posting のままなら、プロセス死などで取り残されたとみなして再 dispatch できる
  POSTING_STALE_AFTER = 10.minutes

  validates :remote_id, :remote_url, :posted_body, :posted_media_digest, :posted_at,
    presence: true, if: :succeeded?
  # Admin でそのままリンクにするので、上流 API の応答をそのまま信じず http(s) に限る
  validates :remote_url, format: {with: %r{\Ahttps?://}i}, if: :succeeded?
  validates :last_error, presence: true, if: :failed?

  # @rbs return: bool
  def posting_in_flight?
    posting? && updated_at > POSTING_STALE_AFTER.ago
  end
  validate :text_and_target_share_announcement

  # 別告知の Text と TargetPlatform を組み合わせる不整合をガードする
  private def text_and_target_share_announcement
    return if social_announcement_text&.social_announcement_id ==
      social_announcement_target_platform&.social_announcement_id

    errors.add(:base, "text and target_platform must belong to the same announcement")
  end
end
