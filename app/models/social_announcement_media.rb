class SocialAnnouncementMedia < ApplicationRecord
  self.table_name = "social_announcement_media"

  MAX_PER_ANNOUNCEMENT = 4
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  ALLOWED_CONTENT_TYPES = IMAGE_CONTENT_TYPES
  # X: 画像5MB / Mastodon: 画像16MB / Bluesky: 画像2MB → 共通の最小値
  MAX_IMAGE_BYTE_SIZE = 2.megabytes

  belongs_to :social_announcement, inverse_of: :media
  has_one_attached :file

  validates :file, presence: true
  validates :alt_text_ja, :alt_text_en, length: {maximum: 1000}, allow_blank: true
  validate :file_content_type
  validate :file_size_within_limit
  validate :count_within_limit, on: :create

  scope :ordered, -> { order(:position, :id) }

  # @rbs return: bool
  def image?
    file.attached? && IMAGE_CONTENT_TYPES.include?(file.content_type)
  end

  # 投稿する Text の locale に対応する alt text。未入力は空文字
  # @rbs locale: String
  # @rbs return: String
  def alt_text_for(locale)
    case locale
    when "ja" then alt_text_ja
    when "en" then alt_text_en
    else raise ArgumentError, "unknown locale: #{locale}"
    end.to_s
  end

  private def file_content_type
    return unless file.attached?
    return if ALLOWED_CONTENT_TYPES.include?(file.content_type)

    errors.add(:file, "content type #{file.content_type} is not allowed")
  end

  private def file_size_within_limit
    return unless file.attached?
    return if file.byte_size <= MAX_IMAGE_BYTE_SIZE

    errors.add(:file, "exceeds #{MAX_IMAGE_BYTE_SIZE / 1.megabyte}MB")
  end

  private def count_within_limit
    return if social_announcement.nil?
    return if social_announcement.media.count < MAX_PER_ANNOUNCEMENT

    errors.add(:base, "max #{MAX_PER_ANNOUNCEMENT} media per announcement")
  end
end
