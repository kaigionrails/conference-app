require "rails_helper"

RSpec.describe Social::XOauth do
  describe ".build_authorization" do
    it "builds a PKCE S256 authorize URL" do
      auth = described_class.build_authorization
      uri = URI.parse(auth.url)
      query = Rack::Utils.parse_query(uri.query)
      expect(uri.host).to eq("x.com")
      expect(query["client_id"]).to eq("test")
      expect(query["code_challenge_method"]).to eq("S256")
      expect(query["state"]).to eq(auth.state)
      expect(query["scope"]).to eq(SocialOauthToken::X_SCOPES.join(" "))
      expected = Base64.urlsafe_encode64(Digest::SHA256.digest(auth.code_verifier), padding: false)
      expect(query["code_challenge"]).to eq(expected)
    end
  end

  describe ".exchange_code!" do
    it "posts to the token endpoint with basic auth" do
      stub = stub_request(:post, "https://api.x.com/2/oauth2/token")
        .with(headers: {"Authorization" => "Basic #{Base64.strict_encode64("test:test")}"}) { |req|
          body = Rack::Utils.parse_query(req.body)
          body["grant_type"] == "authorization_code" && body["code"] == "c" && body["code_verifier"] == "v"
        }
        .to_return(status: 200, body: {access_token: "a", refresh_token: "r", expires_in: 7200}.to_json, headers: {"Content-Type" => "application/json"})

      body = described_class.exchange_code!(code: "c", code_verifier: "v")
      expect(stub).to have_been_requested
      expect(body["access_token"]).to eq("a")
    end

    it "raises PostError on invalid_grant" do
      stub_request(:post, "https://api.x.com/2/oauth2/token")
        .to_return(status: 400, body: {error: "invalid_grant"}.to_json, headers: {"Content-Type" => "application/json"})
      expect { described_class.exchange_code!(code: "c", code_verifier: "v") }.to raise_error(Social::PostError, /invalid_grant/)
    end
  end

  describe ".revoke!" do
    it "posts the token to the revoke endpoint with basic auth" do
      stub = stub_request(:post, "https://api.x.com/2/oauth2/revoke")
        .with(headers: {"Authorization" => "Basic #{Base64.strict_encode64("test:test")}"}) { |req|
          body = Rack::Utils.parse_query(req.body)
          body["token"] == "r1" && body["token_type_hint"] == "refresh_token" && body["client_id"] == "test"
        }
        .to_return(status: 200, body: {revoked: true}.to_json, headers: {"Content-Type" => "application/json"})

      described_class.revoke!(token: "r1", token_type_hint: "refresh_token")
      expect(stub).to have_been_requested
    end

    it "raises PostError on failure" do
      stub_request(:post, "https://api.x.com/2/oauth2/revoke").to_return(status: 400, body: {error: "invalid_request"}.to_json, headers: {"Content-Type" => "application/json"})
      expect { described_class.revoke!(token: "r1", token_type_hint: "refresh_token") }.to raise_error(Social::PostError, /invalid_request/)
    end
  end

  describe ".user_access_token!" do
    it "raises when not connected" do
      expect { described_class.user_access_token! }.to raise_error(Social::PostError, /not connected/)
    end

    it "returns the stored token when not expiring soon" do
      FactoryBot.create(:social_oauth_token, access_token: "a")
      expect(described_class.user_access_token!).to eq("a")
    end

    it "refreshes before expiry and rotates the refresh token" do
      token = FactoryBot.create(:social_oauth_token, access_token: "a", refresh_token: "r1", access_token_expires_at: 1.minute.from_now)
      stub = stub_request(:post, "https://api.x.com/2/oauth2/token")
        .with { |req| Rack::Utils.parse_query(req.body)["refresh_token"] == "r1" }
        .to_return(status: 200, body: {access_token: "a2", refresh_token: "r2", expires_in: 7200, scope: "tweet.write"}.to_json, headers: {"Content-Type" => "application/json"})

      expect(described_class.user_access_token!).to eq("a2")
      expect(stub).to have_been_requested
      token.reload
      expect(token.refresh_token).to eq("r2")
      expect(token.scopes).to eq("tweet.write")
      expect(token.access_token_expires_at).to be > 1.hour.from_now
    end

    it "raises PostError and keeps the row on invalid_grant" do
      FactoryBot.create(:social_oauth_token, access_token_expires_at: 1.minute.from_now)
      stub_request(:post, "https://api.x.com/2/oauth2/token")
        .to_return(status: 400, body: {error: "invalid_grant"}.to_json, headers: {"Content-Type" => "application/json"})
      expect { described_class.user_access_token! }.to raise_error(Social::PostError, /invalid_grant/)
      expect(SocialOauthToken.count).to eq(1)
    end
  end
end
