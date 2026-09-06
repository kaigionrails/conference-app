module Social
  # X OAuth 2.0 Authorization Code + PKCE (User Context)。
  # authorize URL の組み立て、code 交換、refresh、接続済みトークンの取得を担う。
  module XOauth
    AUTHORIZE_URL = "https://x.com/i/oauth2/authorize"
    API_BASE = "https://api.x.com"
    TOKEN_PATH = "/2/oauth2/token"
    REVOKE_PATH = "/2/oauth2/revoke"
    ME_PATH = "/2/users/me"

    Authorization = Data.define(:url, :state, :code_verifier)

    # @rbs return: Social::XOauth::Authorization
    def self.build_authorization
      code_verifier = SecureRandom.urlsafe_base64(64)
      state = SecureRandom.urlsafe_base64(32)
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      query = {
        response_type: "code",
        client_id: config.x_client_id,
        redirect_uri: config.x_redirect_uri,
        scope: SocialOauthToken::X_SCOPES.join(" "),
        state: state,
        code_challenge: challenge,
        code_challenge_method: "S256"
      }
      Authorization.new(url: "#{AUTHORIZE_URL}?#{query.to_query}", state: state, code_verifier: code_verifier)
    end

    # @rbs code: String
    # @rbs code_verifier: String
    # @rbs return: Hash[String, untyped]
    def self.exchange_code!(code:, code_verifier:)
      token_request(
        grant_type: "authorization_code",
        code: code,
        redirect_uri: config.x_redirect_uri,
        code_verifier: code_verifier,
        client_id: config.x_client_id
      )
    end

    # @rbs refresh_token: String
    # @rbs return: Hash[String, untyped]
    def self.refresh!(refresh_token:)
      token_request(
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: config.x_client_id
      )
    end

    # @rbs access_token: String
    # @rbs return: Hash[String, untyped] -- {"id" =>, "username" =>, "name" =>}
    def self.me!(access_token:)
      response = connection.get(ME_PATH) do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end
      raise PostError, "X API #{response.status}: #{response.body}" unless response.success?

      response.body.fetch("data")
    end

    # 接続済みの user access token を返す。期限が近ければ行ロックのうえ refresh する。
    # @rbs force_refresh: bool
    # @rbs return: String
    def self.user_access_token!(force_refresh: false)
      SocialOauthToken.transaction do
        record = SocialOauthToken.lock.find_by(platform: "x")
        raise PostError, "X is not connected" unless record

        record.refresh! if force_refresh || record.expires_soon?
        record.access_token
      end
    end

    # X 側でトークンを失効させる (RFC 7009)。切断・再接続で DB から消す前に呼ぶ
    # @rbs token: String
    # @rbs token_type_hint: String -- "refresh_token" | "access_token"
    # @rbs return: void
    def self.revoke!(token:, token_type_hint:)
      oauth_post(REVOKE_PATH, token: token, token_type_hint: token_type_hint, client_id: config.x_client_id)
    end

    # @rbs params: Hash[Symbol, String]
    # @rbs return: Hash[String, untyped]
    def self.token_request(params)
      oauth_post(TOKEN_PATH, params)
    end
    private_class_method :token_request

    # confidential client として Basic 認証でフォーム POST する
    # @rbs path: String
    # @rbs params: Hash[Symbol, String]
    # @rbs return: Hash[String, untyped]
    def self.oauth_post(path, params)
      client_id = config.x_client_id
      client_secret = config.x_client_secret
      raise PostError, "X client credentials are not configured" if client_id.blank? || client_secret.blank?

      response = connection.post(path) do |req|
        req.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(params)
      end
      unless response.success?
        error = response.body.is_a?(Hash) ? response.body["error"] : nil
        raise PostError, "X OAuth #{response.status}: #{error || response.body}"
      end
      response.body
    end
    private_class_method :oauth_post

    def self.connection
      Faraday.new(API_BASE, request: Social::HTTP_TIMEOUTS) do |b|
        b.response :json, content_type: /\bjson$/
      end
    end
    private_class_method :connection

    def self.config
      Rails.configuration.x.social
    end
    private_class_method :config
  end
end
