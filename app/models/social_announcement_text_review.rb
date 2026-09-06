class SocialAnnouncementTextReview < ApplicationRecord
  belongs_to :social_announcement_text
  belongs_to :reviewed_by, class_name: "User"

  validates :body_digest, presence: true
  validates :media_digest, presence: true
  validates :reviewed_at, presence: true
  validates :reviewed_by_id, uniqueness: {
    scope: [:social_announcement_text_id, :body_digest, :media_digest]
  }

  # レビュー作成のファクトリ。Text の現時点の本文とメディアセットをスナップショットして承認する。
  # 過去にレビューした版へ戻した場合の再レビューでは、同じ digest の行を作り直さず
  # reviewed_at を更新する (レビュアー + digest のユニーク制約はそのまま)。
  # @rbs text: SocialAnnouncementText
  # @rbs reviewer: User
  # @rbs return: SocialAnnouncementTextReview
  def self.create_for!(text, reviewer:)
    review = find_or_initialize_by(
      social_announcement_text: text,
      reviewed_by: reviewer,
      body_digest: text.current_body_digest,
      media_digest: text.social_announcement.current_media_digest
    )
    review.update!(reviewed_at: Time.current)
    review
  end
end
