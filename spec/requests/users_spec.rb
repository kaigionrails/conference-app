require "rails_helper"

RSpec.describe "Users", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2023") }

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

    context "profile exchanged friends" do
      context "no profile exchanged" do
        it "should not display '知り合った人達'" do
          get "/@foo"
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("知り合った人達")
        end
      end

      context "with exchanged profiles" do
        let(:friend) { FactoryBot.create(:user, :with_profile_image, name: "bar") }
        let!(:event2) { FactoryBot.create(:event, name: "Kaigi on Rails 2024") }

        before do
          ProfileExchange.create!(event: event, user: user, friend: friend)
          ProfileExchange.create!(event: event, user: friend, friend: user)
        end

        it "should display '知り合った人達' and friend name" do
          get "/@foo"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Kaigi on Rails 2023で知り合った人達(1人)")
          expect(response.body).to include("@bar")
          expect(response.body).not_to include("Kaigi on Rails 2024で知り合った人達")
        end
      end

      context "with exchanged profiles, past event" do
        let(:friend1) { FactoryBot.create(:user, :with_profile_image, name: "bar") }
        let(:friend2) { FactoryBot.create(:user, :with_profile_image, name: "baz") }
        let!(:event2) { FactoryBot.create(:event, name: "Kaigi on Rails 2024") }

        before do
          ProfileExchange.create!(event: event, user: user, friend: friend1)
          ProfileExchange.create!(event: event, user: friend1, friend: user)
          ProfileExchange.create!(event: event2, user: user, friend: friend2)
          ProfileExchange.create!(event: event2, user: friend2, friend: user)
        end

        it "should display '知り合った人達' and friend name" do
          get "/@foo"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Kaigi on Rails 2023で知り合った人達(1人)")
          expect(response.body).to include("@bar")
          expect(response.body).to include("Kaigi on Rails 2024で知り合った人達(1人)")
          expect(response.body).to include("一覧を見る")
          expect(response.body).to include("@baz")
        end
      end
    end
  end
end
