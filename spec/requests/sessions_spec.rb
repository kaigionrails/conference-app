require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /auth/:provider/callback" do
    context "unknown provider" do
      it "should redirect to /login" do
        get "/auth/foobar/callback"
        expect(response).to redirect_to(login_path)
      end
    end

    context "provider is GitHub" do
      context "exists user" do
        let(:user) { FactoryBot.create(:user, name: "octocat") }
        let(:authentication_provider_github) { FactoryBot.create(:authentication_provider_github, user: user) }
        let!(:auth_uid) { authentication_provider_github.uid }

        before do
          OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
            provider: :github,
            uid: auth_uid
          })
        end

        it "should redirect to root_path" do
          get "/auth/github/callback"
          expect(response).to redirect_to(root_path)
          expect(session[:user_id]).to eq user.id
        end
      end

      context "create new user" do
        let(:event) { FactoryBot.create(:event) }
        let!(:announcement) { FactoryBot.create(:announcement, :published, event: event) }
        let!(:draft_announcement) { FactoryBot.create(:announcement, event: event) }
        let(:auth_hash) { { "info" => { "nickname" => "octocat" }, "uid" => "583231"} } # https://github.com/octocat

        before do
          Event::ONGOING_EVENT_SLUG = event.slug # dirty hack
          OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(auth_hash)
        end

        it "should create user, authentication_provider_github, profile, unread_announcement and enqueue job" do
          expect { get "/auth/github/callback" }.to change {
            AuthenticationProviderGithub.count }.by(1).and change {
              User.count
            }.by(1).and change { Profile.count }.by(1).and have_enqueued_job(DetermineUserRoleJob).and change {
              UnreadAnnouncement.count }.by(1)
        end
      end
    end
  end
end
