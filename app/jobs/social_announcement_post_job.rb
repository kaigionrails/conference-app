class SocialAnnouncementPostJob < ApplicationJob
  # 投稿は成功したが、その間に claim を失った。retry_on の対象外
  class ClaimLost < StandardError; end

  queue_as :default

  retry_on Social::PostError, wait: :polynomially_longer, attempts: 5 do |job, error|
    text_id, target_platform_id = job.arguments
    post = SocialAnnouncementPost.find_by(
      social_announcement_text_id: text_id,
      social_announcement_target_platform_id: target_platform_id
    )
    post&.update!(status: :failed, last_error: error.message, last_error_at: Time.current)
  end

  # 外部 API 呼び出しは DB トランザクションの外で行う。トランザクションの中で呼ぶと、
  # X の refresh token ローテーション (SocialOauthToken の更新) が投稿失敗時のロールバックに
  # 巻き込まれ、X 側で既に失効した refresh token が DB に残って接続が死ぬ。
  # 二重投稿は pending -> posting の条件付き UPDATE (1 行取れたジョブだけが投稿する) で防ぐ。
  # @rbs text_id: Integer
  # @rbs target_platform_id: Integer
  # @rbs return: void
  def perform(text_id, target_platform_id)
    text = SocialAnnouncementText.find(text_id)
    target = SocialAnnouncementTargetPlatform.find(target_platform_id)
    post = SocialAnnouncementPost.find_by!(
      social_announcement_text: text,
      social_announcement_target_platform: target
    )

    return unless text.social_announcement_id == target.social_announcement_id
    return unless text.approved?
    return if claim(post, from: "pending", to: "posting") == 0

    announcement = text.social_announcement
    media_digest = announcement.current_media_digest
    attachments = announcement.media_for_post.map { |m|
      Social::Attachment.new(file: m.file, alt_text: m.alt_text_for(text.locale))
    }
    begin
      result = Social.client_for(target.platform).post(
        text: text.body,
        media: attachments,
        langs: [text.locale],
        idempotency_key: ["social-announcement", text.id, target.id, text.current_body_digest, media_digest].join(":")
      )
    rescue
      # リトライ (または retry_on の failed 化) が再び claim できるよう pending に戻す
      claim(post, from: "posting", to: "pending")
      raise
    end

    post.assign_attributes(
      status: :succeeded,
      remote_id: result.remote_id,
      remote_url: result.remote_url,
      posted_body: text.body,
      posted_media_digest: media_digest,
      posted_at: Time.current,
      last_error: nil,
      last_error_at: nil
    )
    post.validate!
    # 投稿中に claim を失っていたら (stale 扱いで再 dispatch されたなど) 上書きしない。
    # SNS 側の投稿は取り消せないので、retry せず例外で Sentry に上げて人が対処する
    updated = SocialAnnouncementPost.where(id: post.id, status: "posting")
      .update_all(post.changes.transform_values(&:last).merge(updated_at: Time.current))
    if updated == 0
      raise ClaimLost, "post #{post.id} lost its posting claim; remote post exists at #{result.remote_url}"
    end
    announcement.sync_published_at!
  end

  # 条件付き UPDATE。更新できた行数 (0 か 1) を返す
  # @rbs post: SocialAnnouncementPost
  # @rbs from: String
  # @rbs to: String
  # @rbs return: Integer
  private def claim(post, from:, to:)
    SocialAnnouncementPost.where(id: post.id, status: from).update_all(status: to, updated_at: Time.current)
  end
end
