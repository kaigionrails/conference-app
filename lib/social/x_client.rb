module Social
  class XClient < BaseClient
    API_BASE = "https://api.x.com"
    TWEETS_PATH = "/2/tweets"
    MEDIA_UPLOAD_PATH = "/2/media/upload"
    MEDIA_METADATA_PATH = "/2/media/metadata"

    def post(text:, media: [], langs: [], idempotency_key: nil)
      token = XOauth.user_access_token!
      media_ids = media.map { |m| upload_media(m, access_token: token) }

      body = {text: text}
      body[:media] = {media_ids: media_ids} if media_ids.any?

      response = connection(token).post(TWEETS_PATH, body.to_json)
      if response.status == 401
        token = XOauth.user_access_token!(force_refresh: true)
        response = connection(token).post(TWEETS_PATH, body.to_json)
      end
      raise PostError, "X API #{response.status}: #{response.body}" unless response.success?

      data = response.body.fetch("data")
      screen_name = SocialOauthToken.find_by!(platform: "x").screen_name
      Result.new(
        remote_id: data.fetch("id"),
        remote_url: "https://x.com/#{screen_name}/status/#{data.fetch("id")}"
      )
    end

    # @rbs access_token: String
    # @rbs return: Faraday::Connection
    private def connection(access_token)
      Faraday.new(API_BASE, request: Social::HTTP_TIMEOUTS) do |b|
        b.request :json
        b.response :json, content_type: /\bjson$/
        b.headers["Authorization"] = "Bearer #{access_token}"
      end
    end

    # 初回は 2MB 以下の画像のみ。simple upload で足りる。
    # 続けて media metadata で alt_text を付ける。Bearer は user access token。
    # @rbs media: Social::Attachment
    # @rbs access_token: String
    # @rbs return: String -- media_id
    private def upload_media(media, access_token:)
      blob = media.file.blob
      upload = Faraday.new(API_BASE, request: Social::HTTP_TIMEOUTS) do |b|
        b.request :multipart
        b.response :json, content_type: /\bjson$/
        b.headers["Authorization"] = "Bearer #{access_token}"
      end
      response = blob.open do |tempfile|
        upload.post(MEDIA_UPLOAD_PATH, {
          media_category: "tweet_image",
          media: Faraday::Multipart::FilePart.new(tempfile.path, blob.content_type, blob.filename.to_s)
        })
      end
      raise PostError, "X media upload #{response.status}: #{response.body}" unless response.success?

      media_id = response.body.fetch("data").fetch("id")
      if media.alt_text.present?
        meta = connection(access_token).post(MEDIA_METADATA_PATH, {
          id: media_id, metadata: {alt_text: {text: media.alt_text}}
        }.to_json)
        raise PostError, "X media metadata #{meta.status}: #{meta.body}" unless meta.success?
      end
      media_id
    end
  end
end
