module Social
  # AT Protocol。アプリパスワードでセッションを作り、投稿ごとに JWT を取り直す
  class BlueskyClient < BaseClient
    PDS_HOST = "https://bsky.social"

    # @rbs config: untyped -- Rails.configuration.x.social
    def initialize(config: Rails.configuration.x.social)
      @config = config
      @session = nil
    end

    def post(text:, media: [], langs: [], idempotency_key: nil)
      ensure_session!

      record = {
        "$type" => "app.bsky.feed.post",
        "text" => text,
        "createdAt" => Time.current.iso8601(3),
        "langs" => langs
      }

      if media.any?
        blobs = media.map { |m| upload_blob(m.file.blob) }
        record["embed"] = {
          "$type" => "app.bsky.embed.images",
          "images" => media.zip(blobs).map { |m, b| {"alt" => m.alt_text.to_s, "image" => b} }
        }
      end

      response = connection.post("/xrpc/com.atproto.repo.createRecord") do |req|
        req.headers["Authorization"] = "Bearer #{@session["accessJwt"]}"
        req.headers["Content-Type"] = "application/json"
        req.body = {repo: @session["did"], collection: "app.bsky.feed.post", record: record}.to_json
      end
      raise PostError, "Bluesky #{response.status}: #{response.body}" unless response.success?

      data = response.body
      rkey = data.fetch("uri").split("/").last
      Result.new(
        remote_id: data.fetch("uri"),
        remote_url: "https://bsky.app/profile/#{handle}/post/#{rkey}"
      )
    end

    # @rbs return: String
    private def handle
      require_credential!(@config.bluesky_handle, "SOCIAL_BLUESKY_HANDLE")
    end

    # @rbs return: Faraday::Connection
    private def connection
      Faraday.new(PDS_HOST, request: Social::HTTP_TIMEOUTS) do |b|
        b.response :json, content_type: /\bjson$/
      end
    end

    private def ensure_session!
      return if @session

      password = require_credential!(@config.bluesky_app_password, "SOCIAL_BLUESKY_APP_PASSWORD")
      response = connection.post("/xrpc/com.atproto.server.createSession") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {identifier: handle, password: password}.to_json
      end
      raise PostError, "Bluesky auth failed: #{response.status}" unless response.success?

      @session = response.body
    end

    # com.atproto.repo.uploadBlob でバイナリを送信し blob 参照を返す
    # @rbs blob: ActiveStorage::Blob
    # @rbs return: Hash[String, untyped]
    private def upload_blob(blob)
      response = connection.post("/xrpc/com.atproto.repo.uploadBlob") do |req|
        req.headers["Authorization"] = "Bearer #{@session["accessJwt"]}"
        req.headers["Content-Type"] = blob.content_type
        req.body = blob.download
      end
      raise PostError, "Bluesky blob upload #{response.status}: #{response.body}" unless response.success?

      response.body.fetch("blob")
    end
  end
end
