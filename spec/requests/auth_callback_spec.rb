require "rails_helper"

RSpec.describe "AuthCallback", type: :request do
  describe "GET /auth/:provider/callback" do
    context "unknown provider" do
      it "should redirect to /login" do
        get "/auth/foobar/callback"
        expect(response).to redirect_to(login_path)
      end
    end

    context "with an additional registered provider" do
      # Reloaded so the stub returns an existing user: the instance create
      # hands back still reports previously_new_record?, which the callback
      # reads as a first login.
      let(:user) { FactoryBot.create(:user).reload }
      let(:auth) { OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "google-user") }
      let(:provider) { double("Authentication provider") }

      # google_oauth2 is registered with OmniAuth, so its test mode answers the
      # callback and replaces omniauth.auth and omniauth.params; the auth hash
      # goes through mock_auth and return_to through the request phase instead.
      before do
        stub_const("AuthCallbackController::PROVIDERS", AuthCallbackController::PROVIDERS.merge("google_oauth2" => provider))
        OmniAuth.config.mock_auth[:google_oauth2] = auth
        allow(provider).to receive(:find_or_create_user_from_auth_hash).with(auth).and_return(user)
      end

      it "uses the same return location after authentication" do
        return_to = "/sponsor_stamp_cards/2026/stamps/new?code=stamp-code&locale=en"

        post "/auth/google_oauth2?#{{return_to:}.to_query}"
        follow_redirect!

        expect(response).to redirect_to(return_to)
        expect(session[:user_id]).to eq(user.id)
      end

      it "uses the default page when no return location was provided" do
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(setting_path)
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "provider is GitHub" do
      # The avatar URL is looked up through Octokit before Profile is asked to
      # attach it, so the lookup needs a stub of its own.
      before do
        stub_request(:get, %r{\Ahttps://api\.github\.com/user/\d+\z})
          .to_return(
            body: {avatar_url: "https://avatars.example.invalid/octocat.png"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

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

        it "returns to the stamp URL after GitHub login" do
          return_to = "/sponsor_stamp_cards/2026/stamps/new?code=stamp-code&locale=en"
          post "/auth/github?#{{return_to:}.to_query}"
          follow_redirect!

          expect(response).to redirect_to(return_to)
          expect(session[:user_id]).to eq(user.id)
        end

        it "should redirect to root_path" do
          get "/auth/github/callback"
          expect(response).to redirect_to(setting_path)
          expect(session[:user_id]).to eq user.id
        end

        it "does not prompt for the profile" do
          get "/auth/github/callback"
          expect(flash[:notice]).to be_nil
        end
      end

      context "create new user" do
        let(:event) { FactoryBot.create(:event) }
        let!(:announcement) { FactoryBot.create(:announcement, :published, event: event) }
        let!(:draft_announcement) { FactoryBot.create(:announcement, event: event) }
        let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
        let(:auth_hash) { {"info" => {"nickname" => "octocat"}, "uid" => "583231"} } # https://github.com/octocat

        before do
          OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(auth_hash)
          expect_any_instance_of(Profile).to receive(:ensure_image_from).and_return(nil)
        end

        it "should create user, authentication_provider_github, profile, unread_announcement and enqueue job" do
          expect { get "/auth/github/callback" }.to change {
                                                      AuthenticationProviderGithub.count
                                                    }.by(1).and change {
                                                                  User.count
                                                                }.by(1).and change {
                                                                              Profile.count
                                                                            }.by(1).and have_enqueued_job(
                                                                              DetermineUserRoleJob
                                                                            ).and change {
                                                                                    UnreadAnnouncement.count
                                                                                  }.by(1)
        end

        it "names the user and the profile after the GitHub username" do
          get "/auth/github/callback"

          user = User.last
          expect(user.name).to eq "octocat"
          expect(user.profile.name).to eq "octocat"
        end

        it "sends the user to the profile form with a prompt" do
          get "/auth/github/callback"

          expect(response).to redirect_to(edit_profile_path(User.last.profile))
          expect(flash[:notice]).to be_present
        end

        it "still returns to the stamp URL, with a prompt" do
          return_to = "/sponsor_stamp_cards/2026/stamps/new?code=stamp-code&locale=en"
          post "/auth/github?#{{return_to:}.to_query}"
          follow_redirect!

          expect(response).to redirect_to(return_to)
          expect(flash[:notice]).to be_present
        end
      end

      context "create new user whose GitHub username is unavailable" do
        let(:auth_hash) { {"info" => {"nickname" => nickname}, "uid" => "583231"} }

        before do
          OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(auth_hash)
          expect_any_instance_of(Profile).to receive(:ensure_image_from).and_return(nil)
        end

        shared_examples "falls back to a generated handle" do
          it "generates a handle but keeps the GitHub username as the display name" do
            expect { get "/auth/github/callback" }.to change { User.count }.by(1)

            user = User.last
            expect(user.name).to match(/\Auser-[a-z0-9]{6}\z/)
            expect(user.profile.name).to eq nickname
          end
        end

        context "because another user already holds it" do
          let(:nickname) { "octocat" }

          before { FactoryBot.create(:user, name: "OctoCat") }

          include_examples "falls back to a generated handle"
        end

        context "because it is reserved" do
          let(:nickname) { "admin" }

          include_examples "falls back to a generated handle"
        end
      end
    end

    context "provider is Google" do
      let(:event) { FactoryBot.create(:event) }
      let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
      let(:auth_hash) do
        {
          "provider" => "google_oauth2",
          "uid" => "108532000000000000001",
          "info" => {"name" => "Yusuke Nakamura", "image" => "https://lh3.example.invalid/a/yusuke.jpg"}
        }
      end

      before do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(auth_hash)
      end

      context "create new user" do
        before { expect_any_instance_of(Profile).to receive(:ensure_image_from).and_return(nil) }

        it "creates the user, the provider and the profile" do
          expect { get "/auth/google_oauth2/callback" }.to change {
            AuthenticationProviderGoogle.count
          }.by(1).and change { User.count }.by(1).and change { Profile.count }.by(1)
        end

        it "logs the user in and gives them a generated handle" do
          get "/auth/google_oauth2/callback"

          user = User.last
          expect(session[:user_id]).to eq user.id
          expect(user.name).to match(/\Auser-[a-z0-9]{6}\z/)
          expect(user.profile.name).to eq "Yusuke Nakamura"
          expect(response).to redirect_to(edit_profile_path(user.profile))
          expect(flash[:notice]).to be_present
        end
      end

      context "exists user" do
        let!(:existing) { FactoryBot.create(:authentication_provider_google, uid: "108532000000000000001") }

        it "signs the existing user in without creating another" do
          expect { get "/auth/google_oauth2/callback" }.not_to change { User.count }

          expect(session[:user_id]).to eq existing.user.id
        end

        it "lands on the default page without a prompt" do
          get "/auth/google_oauth2/callback"

          expect(response).to redirect_to(setting_path)
          expect(flash[:notice]).to be_nil
        end
      end
    end
  end
end
