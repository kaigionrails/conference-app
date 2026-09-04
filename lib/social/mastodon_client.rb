module Social
  class MastodonClient < BaseClient
    # @rbs config: untyped -- Rails.configuration.x.social
    def initialize(config: Rails.configuration.x.social)
      @config = config
    end

    def post(text:, media: [], langs: [], idempotency_key: nil)
      media_ids = media.map { |m| upload_media(m) }

      response = connection.post("/api/v1/statuses") do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["Idempotency-Key"] = idempotency_key if idempotency_key
        req.body = {status: text, visibility: "public", media_ids: media_ids}.compact_blank.to_json
      end
      raise PostError, "Mastodon #{response.status}: #{response.body}" unless response.success?

      json = response.body
      Result.new(remote_id: json.fetch("id"), remote_url: json.fetch("url"))
    end

    # アクセストークンを Bearer で送るので、平文 http や設定ミスで別ホストへ飛ばないよう https のみ許す
    # @rbs return: String
    private def base_url
      url = require_credential!(@config.mastodon_base_url, "SOCIAL_MASTODON_BASE_URL").to_s.chomp("/")
      raise PostError, "SOCIAL_MASTODON_BASE_URL must be an https URL" unless url.match?(%r{\Ahttps://[^/\s]+\z}i)

      url
    end

    # @rbs return: String
    private def access_token
      require_credential!(@config.mastodon_access_token, "SOCIAL_MASTODON_ACCESS_TOKEN")
    end

    # @rbs return: Faraday::Connection
    private def connection
      Faraday.new(base_url, request: Social::HTTP_TIMEOUTS) do |b|
        b.request :multipart
        b.response :json, content_type: /\bjson$/
        b.headers["Authorization"] = "Bearer #{access_token}"
      end
    end

    # @rbs media: Social::Attachment
    # @rbs return: String -- media id
    private def upload_media(media)
      blob = media.file.blob
      response = blob.open do |tempfile|
        payload = {file: Faraday::Multipart::FilePart.new(tempfile.path, blob.content_type, blob.filename.to_s)}
        payload[:description] = media.alt_text if media.alt_text.present?
        connection.post("/api/v2/media", payload)
      end
      # 202 は非同期処理中だが id は返る。statuses 側が処理完了を待つ
      raise PostError, "Mastodon media upload #{response.status}: #{response.body}" unless response.success?

      response.body.fetch("id")
    end
  end
end
