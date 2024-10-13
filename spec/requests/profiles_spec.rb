require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }
  let(:user) { FactoryBot.create(:user) }
  let!(:profile) { FactoryBot.create(:profile, :with_image, user: user) }

  describe "GET /index" do
    before do
      sign_in(user)
    end

    it "returns http success" do
      get "/profiles"
      expect(response).to have_http_status(:success)
    end

    context "profile exchanged friends" do
      context "no profile exchanged" do
        it "should not display '知り合った人達'" do
          get "/profiles"
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
          get "/profiles"
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
          get "/profiles"
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
