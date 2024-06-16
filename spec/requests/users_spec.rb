require "rails_helper"

RSpec.describe "Users", type: :request do
  before { prepare_current_event }
  describe "GET /@:username" do
    let!(:user) { FactoryBot.create(:user, :with_profile_image, name: "foo") }
    context "not logged in" do
      context "when no token" do
        it "should success, no effects" do
          get "/@foo"
          expect(response).to have_http_status(:success)
          expect(ProfileExchange.count).to eq 0
        end
      end

      context "when invalid token" do
        it "should success, no effects" do
          get "/@foo?token=invalidinvalidinvalid"
          expect(response).to have_http_status(:success)
          expect(ProfileExchange.count).to eq 0
        end
      end

      context "when valid token" do
        it "should success, no effects" do
          get "/@foo?token=invalidinvalidinvalid"
          expect(response).to have_http_status(:success)
          expect(ProfileExchange.count).to eq 0
        end
      end
    end

    context "logged in" do
      before { sign_in(user) }
      context "show own profile" do
        context "when no token" do
          it "should success, no effects" do
            get "/@foo"
            expect(response).to have_http_status(:success)
            expect(ProfileExchange.count).to eq 0
          end
        end

        context "when valid token" do
          let(:token) { JWT.encode({iss: user.name, iat: 1.second.ago.to_i, exp: 5.minutes.since.to_i}, nil, "none") }
          it "should success, no effects" do
            get "/@foo?token=#{token}"
            expect(response).to have_http_status(:success)
            expect(ProfileExchange.count).to eq 0
          end
        end
      end

      context "show other's profile" do
        let(:other_user) { FactoryBot.create(:user, :with_profile_image, name: "bar") }
        let(:token) { JWT.encode({iss: other_user.name, iat: 1.second.ago.to_i, exp: 5.minutes.since.to_i}, nil, "none") }
        it "should success, create profile_exchanges" do
          get "/@bar?token=#{token}"
          expect(response).to have_http_status(:success)
          expect(ProfileExchange.count).to eq 2
          get "/@bar?token=#{token}" # twice!
          expect(ProfileExchange.count).to eq 2 # not changed
        end
      end
    end
  end
end
