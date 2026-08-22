module Social
  class PostError < StandardError; end

  Result = Data.define(:remote_id, :remote_url)

  # クライアントに渡す添付。alt_text は投稿する Text の locale で解決済み
  Attachment = Data.define(:file, :alt_text)

  # 全クライアント共通の Faraday タイムアウト。1 投稿あたり最大 10 リクエスト程度
  # (X: 画像 4 枚のアップロード + metadata + tweet) でも POSTING_STALE_AFTER (10 分) を超えないようにする
  HTTP_TIMEOUTS = {open_timeout: 10, timeout: 30}.freeze

  # @rbs return: bool
  def self.dry_run?
    Rails.configuration.x.social.dry_run == true
  end

  # @rbs platform: String
  # @rbs return: Social::BaseClient
  def self.client_for(platform)
    inner = case platform
    when "x" then XClient.new
    when "mastodon" then MastodonClient.new
    when "bluesky" then BlueskyClient.new
    else raise ArgumentError, "unknown platform: #{platform}"
    end
    dry_run? ? DryRunClient.new(inner) : inner
  end
end
