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

        it "lists the person who has just scanned the code" do
          get "/@bar?token=#{token}"
          expect(response.body).to include("Kaigi on Rails 2023で知り合った人達(1人)")
          expect(Nokogiri::HTML(response.body).at_css("ul a[href='/@foo']")).not_to be_nil
        end

        it "counts the exchange just made and pulses the count only on that page" do
          get "/@bar?token=#{token}"
          count = Nokogiri::HTML(response.body).at_css("[data-profile-exchange-count]")
          expect(count.text.squish).to eq "Kaigi on Rails 2023でプロフィールを交換した人 2人"
          expect(count.at_css(".profile-exchange-count--updated")).not_to be_nil

          get "/@bar?token=#{token}" # reloaded
          expect(response.body).not_to include("profile-exchange-count--updated")
        end

        it "stores the missing direction of a one-way exchange, and pulses the count" do
          ProfileExchange.create!(event:, user: other_user, friend: user)

          get "/@bar?token=#{token}"
          expect(ProfileExchange.where(event:, user:, friend: other_user)).to exist
          expect(ProfileExchange.count).to eq 2
          expect(response.body).to include("profile-exchange-count--updated")
        end
      end
    end

    context "login prompt on a smartphone" do
      let(:user_agent) { "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1" }
      let(:token) { JWT.encode({iss: user.name, iat: 1.second.ago.to_i, exp: 5.minutes.since.to_i}, nil, "none") }

      it "is shown to a visitor who is not logged in and came with a token" do
        get "/@foo?token=#{token}", headers: {"User-Agent" => user_agent}
        expect(response.body).to include(I18n.t("users.show.login_prompt"))
      end

      it "is not shown to a visitor who came without a token" do
        get "/@foo", headers: {"User-Agent" => user_agent}
        expect(response.body).not_to include(I18n.t("users.show.login_prompt"))
      end

      it "is not shown to a logged-in user" do
        sign_in(user)
        get "/@foo?token=#{token}", headers: {"User-Agent" => user_agent}
        expect(response.body).not_to include(I18n.t("users.show.login_prompt"))
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

        it "shows friends' images as the :thumb variant, in both lists" do
          get "/@foo"
          [friend1, friend2].each do |friend|
            expect(response.body).to include(friend.profile.images.first.variant(:thumb).variation.key)
          end
        end
      end
    end

    # Shown to visitors who are not logged in as well: it is only a total.
    context "profile exchange count" do
      let(:friend) { FactoryBot.create(:user, :with_profile_image, name: "bar") }
      let(:others) { FactoryBot.create_list(:user, 2) }
      let(:strangers) { FactoryBot.create_list(:user, 2) }
      let(:other_event) { FactoryBot.create(:event, name: "Kaigi on Rails 2024") }

      def exchange(event, user1, user2)
        ProfileExchange.create!(event:, user: user1, friend: user2)
        ProfileExchange.create!(event:, user: user2, friend: user1)
      end

      def count_text
        Nokogiri::HTML(response.body).at_css("[data-profile-exchange-count]")&.text&.squish
      end

      {
        "desktop" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
        "smartphone" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"
      }.each do |device, user_agent|
        it "counts everyone who exchanged at the ongoing event, on #{device}" do
          exchange(event, user, friend)
          exchange(event, others[0], others[1])
          exchange(other_event, strangers[0], strangers[1])

          get "/@foo", headers: {"User-Agent" => user_agent}

          expect(count_text).to eq "Kaigi on Rails 2023でプロフィールを交換した人 4人"
          expect(response.body).not_to include("profile-exchange-count--updated")
        end

        it "shows zero before anyone has exchanged, on #{device}" do
          get "/@foo", headers: {"User-Agent" => user_agent}

          expect(count_text).to eq "Kaigi on Rails 2023でプロフィールを交換した人 0人"
        end
      end
    end

    # A Google account can come without a picture, and anyone can delete all
    # of their images.
    context "profile without images" do
      before { FactoryBot.create(:profile, user: FactoryBot.create(:user, name: "noimage")) }

      {
        "desktop" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
        "smartphone" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"
      }.each do |device, user_agent|
        it "shows the default icon on #{device}" do
          get "/@noimage", headers: {"User-Agent" => user_agent}
          expect(response).to have_http_status(:success)
          expect(response.body).to include("default_user_icon")
        end
      end
    end
  end
end
