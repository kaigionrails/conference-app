require "rails_helper"

RSpec.describe "Admin::SocialXConnections", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }

  before { sign_in(admin) }

  describe "POST /admin/social_x_connection" do
    it "redirects to X authorize URL and stores state in session" do
      post admin_social_x_connection_path
      expect(response).to have_http_status(:redirect)
      expect(response.location).to start_with("https://x.com/i/oauth2/authorize?")
      expect(session[:social_x_oauth]["state"]).to be_present
      expect(session[:social_x_oauth]["code_verifier"]).to be_present
    end
  end

  describe "GET /admin/social_x_connection/callback" do
    def start_connection
      post admin_social_x_connection_path
      session[:social_x_oauth]["state"]
    end

    def stub_token_exchange
      stub_request(:post, "https://api.x.com/2/oauth2/token")
        .to_return(status: 200, body: {access_token: "a", refresh_token: "r", expires_in: 7200, scope: "tweet.write"}.to_json, headers: {"Content-Type" => "application/json"})
    end

    def stub_me(username)
      stub_request(:get, "https://api.x.com/2/users/me")
        .with(headers: {"Authorization" => "Bearer a"})
        .to_return(status: 200, body: {data: {id: "42", username: username, name: "n"}}.to_json, headers: {"Content-Type" => "application/json"})
    end

    it "saves the token when state and screen_name match" do
      state = start_connection
      stub_token_exchange
      stub_me("testuser")

      get admin_social_x_connection_callback_path, params: {state: state, code: "c"}
      expect(response).to redirect_to(admin_social_announcements_path)
      token = SocialOauthToken.find_by!(platform: "x")
      expect(token.access_token).to eq("a")
      expect(token.refresh_token).to eq("r")
      expect(token.screen_name).to eq("testuser")
      expect(token.remote_user_id).to eq("42")
      expect(token.connected_by).to eq(admin)
      expect(flash[:success]).to match(/Connected as @testuser/)
    end

    it "rejects on state mismatch" do
      start_connection
      get admin_social_x_connection_callback_path, params: {state: "wrong", code: "c"}
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:alert]).to match(/state mismatch/)
    end

    it "rejects when code is missing" do
      state = start_connection
      get admin_social_x_connection_callback_path, params: {state: state}
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:alert]).to match(/code is missing/)
    end

    it "rejects when the screen name does not match" do
      state = start_connection
      stub_token_exchange
      stub_me("someoneelse")
      get admin_social_x_connection_callback_path, params: {state: state, code: "c"}
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:alert]).to match(/does not match/)
    end

    it "rejects when token exchange fails" do
      state = start_connection
      stub_request(:post, "https://api.x.com/2/oauth2/token").to_return(status: 400, body: {error: "invalid_request"}.to_json, headers: {"Content-Type" => "application/json"})
      get admin_social_x_connection_callback_path, params: {state: state, code: "c"}
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:alert]).to match(/invalid_request/)
    end

    it "replaces an existing connection and revokes the previous refresh token at X" do
      FactoryBot.create(:social_oauth_token, access_token: "old", refresh_token: "old-refresh")
      state = start_connection
      stub_token_exchange
      stub_me("TestUser")
      revoke = stub_request(:post, "https://api.x.com/2/oauth2/revoke")
        .with { |req| Rack::Utils.parse_query(req.body)["token"] == "old-refresh" }
        .to_return(status: 200, body: {revoked: true}.to_json, headers: {"Content-Type" => "application/json"})

      get admin_social_x_connection_callback_path, params: {state: state, code: "c"}
      expect(revoke).to have_been_requested
      expect(SocialOauthToken.count).to eq(1)
      expect(SocialOauthToken.first.access_token).to eq("a")
      expect(flash[:alert]).to be_nil
    end

    it "does not revoke anything on a first connection" do
      state = start_connection
      stub_token_exchange
      stub_me("testuser")
      get admin_social_x_connection_callback_path, params: {state: state, code: "c"}
      expect(a_request(:post, "https://api.x.com/2/oauth2/revoke")).not_to have_been_made
    end
  end

  describe "DELETE /admin/social_x_connection" do
    it "revokes the refresh token at X and removes the row" do
      FactoryBot.create(:social_oauth_token, refresh_token: "r-to-revoke")
      revoke = stub_request(:post, "https://api.x.com/2/oauth2/revoke")
        .with { |req| Rack::Utils.parse_query(req.body).values_at("token", "token_type_hint") == ["r-to-revoke", "refresh_token"] }
        .to_return(status: 200, body: {revoked: true}.to_json, headers: {"Content-Type" => "application/json"})

      delete admin_social_x_connection_path
      expect(revoke).to have_been_requested
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:success]).to eq("X disconnected")
      expect(flash[:alert]).to be_nil
    end

    it "still removes the row and warns when the revoke fails" do
      FactoryBot.create(:social_oauth_token)
      stub_request(:post, "https://api.x.com/2/oauth2/revoke").to_return(status: 503, body: "{}", headers: {"Content-Type" => "application/json"})

      delete admin_social_x_connection_path
      expect(SocialOauthToken.count).to eq(0)
      expect(flash[:alert]).to match(/connected_apps/)
    end

    it "is a no-op without a connection" do
      delete admin_social_x_connection_path
      expect(a_request(:post, "https://api.x.com/2/oauth2/revoke")).not_to have_been_made
      expect(response).to redirect_to(admin_social_announcements_path)
    end
  end
end
