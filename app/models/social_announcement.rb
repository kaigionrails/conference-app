class SocialAnnouncement < ApplicationRecord
  LOCALES = %w[ja en].freeze
  PLATFORMS = %w[x mastodon bluesky].freeze
  # 告知に付ける想定のハッシュタグ。含まれていなくても投稿は止めず、UI で警告だけ出す。
  # 前後が空白 (全角含む)・改行・文頭文末でないとハッシュタグとして成立しない
  # (直前に文字が続くとタグにならず、直後に CJK が続くと別のタグになる) ので、境界も見る
  RECOMMENDED_HASHTAG = "#kaigionrails".freeze
  RECOMMENDED_HASHTAG_PATTERN = /(?:\A|[[:space:]])#{Regexp.escape(RECOMMENDED_HASHTAG)}(?:[[:space:]]|\z)/i
  # メンションらしきもの (空白または文頭の直後の @ + 英数字)。本文は全プラットフォーム共通なので、
  # 同じ @user が別のアカウントを指す。投稿は止めず UI で警告だけ出す
  MENTION_PATTERN = /(?:\A|[[:space:]])@\w/

  belongs_to :event
  belongs_to :created_by, class_name: "User"
  has_many :texts, class_name: "SocialAnnouncementText", dependent: :destroy
  has_many :target_platforms, class_name: "SocialAnnouncementTargetPlatform", dependent: :destroy
  has_many :media, class_name: "SocialAnnouncementMedia", dependent: :destroy, inverse_of: :social_announcement
  has_many :posts, through: :texts

  accepts_nested_attributes_for :media, allow_destroy: true, reject_if: ->(attrs) { attrs[:file].blank? }

  MAX_MEDIA = SocialAnnouncementMedia::MAX_PER_ANNOUNCEMENT

  validates :campaign, presence: true
  validate :media_composition_valid

  # @rbs return: bool
  def fully_approved?
    texts.any? && texts.all?(&:approved?)
  end

  # @rbs return: Integer
  def expected_post_count
    texts.count * target_platforms.count
  end

  # @rbs return: bool
  def fully_posted?
    expected_post_count > 0 && succeeded_posts.count == expected_post_count
  end

  # @rbs return: Array[SocialAnnouncementMedia]
  def media_for_post
    media.ordered.select { |m| m.file.attached? }
  end

  # 並び・checksum・両 locale の alt_text からメディアセットの指紋を作る。
  # alt を変えても未レビューに戻る。空セットでも安定した hex を返す。
  # @rbs return: String
  def current_media_digest
    payload = media_for_post.map { |m|
      "#{m.position}:#{m.file.blob.checksum}:#{m.alt_text_ja}:#{m.alt_text_en}"
    }.join("|")
    Digest::SHA256.hexdigest(payload)
  end

  # @rbs return: bool
  def x_targeted?
    target_platforms.any? { |t| t.platform == "x" }
  end

  # succeeded と投稿中以外の (Text, TargetPlatform) を pending にして enqueue する
  # @rbs return: void
  def dispatch_all_posts!
    raise Social::PostError, "not fully approved" unless fully_approved?
    raise Social::PostError, "no target platforms" if target_platforms.none?
    if x_targeted? && SocialOauthToken.find_by(platform: "x").nil?
      raise Social::PostError, "X is not connected"
    end

    texts.each do |text|
      target_platforms.each do |target|
        post = SocialAnnouncementPost.find_or_initialize_by(
          social_announcement_text: text,
          social_announcement_target_platform: target
        )
        next if post.succeeded?
        next if post.posting_in_flight?

        post.status = "pending"
        post.last_error = nil
        post.last_error_at = nil
        post.save!
        SocialAnnouncementPostJob.perform_later(text.id, target.id)
      end
    end
  end

  # 全組み合わせが succeeded なら最後の posted_at を入れる。未完了なら nil に戻す
  # (プラットフォーム追加後など)。
  # @rbs return: void
  def sync_published_at!
    if fully_posted?
      update!(published_at: succeeded_posts.maximum(:posted_at))
    elsif published_at.present?
      update!(published_at: nil)
    end
  end

  private def succeeded_posts
    SocialAnnouncementPost
      .joins(:social_announcement_text)
      .where(social_announcement_texts: {social_announcement_id: id}, status: "succeeded")
  end

  private def media_composition_valid
    loaded = media.reject(&:marked_for_destruction?)
    return if loaded.empty?

    unless loaded.all?(&:image?)
      errors.add(:base, "only images are allowed (video support is not in the first release)")
    end
  end
end
