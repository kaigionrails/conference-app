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

        {
          "desktop" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
          "smartphone" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"
        }.each do |device, user_agent|
          it "shows friends' images as the :thumb variant, in both lists, on #{device}" do
            get "/profiles", headers: {"User-Agent" => user_agent}
            [friend1, friend2].each do |friend|
              expect(response.body).to include(friend.profile.images.first.variant(:thumb).variation.key)
            end
          end
        end
      end
    end
  end
  describe "GET /profiles/:id/edit" do
    before { sign_in(user) }

    {
      "desktop" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
      "smartphone" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"
    }.each do |device, user_agent|
      it "shows the images as the :thumb variant and takes several new ones, on #{device}" do
        get "/profiles/#{profile.id}/edit", headers: {"User-Agent" => user_agent}

        expect(response).to have_http_status(:success)
        expect(response.body).to include(profile.images.first.variant(:thumb).variation.key)
        input = Nokogiri::HTML(response.body).at_css('input[type="file"][name="profile[images][]"]')
        expect(input).not_to be_nil
        expect(input["multiple"]).to eq "multiple"
      end

      # A Turbo visit after saving would keep showing an image that failed
      # while its variant was being generated, such as the header icon right
      # after the first login.
      it "saves without Turbo, so the next page is loaded in full, on #{device}" do
        get "/profiles/#{profile.id}/edit", headers: {"User-Agent" => user_agent}

        form = Nokogiri::HTML(response.body).at_css("form[action='#{profile_path(profile)}']")
        expect(form["data-turbo"]).to eq "false"
      end
    end
  end

  describe "PATCH /profiles/:id" do
    before { sign_in(user) }

    def update_with(handle, images: nil)
      profile_params = {name: "表示名", description: "", profile_badge_ids: [""]}
      profile_params[:images] = images unless images.nil?
      patch "/profiles/#{profile.id}", params: {handle: handle, profile: profile_params}
    end

    def sample_image
      Rack::Test::UploadedFile.new(Rails.root.join("spec/assets/sample.png"), "image/png")
    end

    it "adds the images sent to the ones already there" do
      expect { update_with(user.name, images: ["", sample_image, sample_image]) }
        .to change { profile.reload.images.count }.from(1).to(3)
      expect(response).to redirect_to(profiles_path)
    end

    # The multiple file field sends an empty value even when no file was
    # picked.
    it "saves the profile without touching the images when none were picked" do
      expect { update_with(user.name, images: [""]) }.not_to change { profile.reload.images.count }
      expect(response).to redirect_to(profiles_path)
    end

    it "changes the handle" do
      update_with("new-handle")

      expect(user.reload.name).to eq "new-handle"
      expect(response).to redirect_to(profiles_path)
    end

    it "leaves the handle alone when the field is blank" do
      before_name = user.name

      update_with("")

      expect(user.reload.name).to eq before_name
    end

    # Handles taken before the handle validation existed can fail it now. The
    # form always sends the current handle, and that must not stop the rest of
    # the profile from being saved.
    context "when the user keeps a handle that predates the validation" do
      before { user.update_column(:name, "admin") }

      it "saves the profile" do
        update_with("admin")

        expect(response).to redirect_to(profiles_path)
        expect(profile.reload.name).to eq "表示名"
        expect(user.reload.name).to eq "admin"
      end
    end

    # A rejected handle has several possible reasons, so the message has to
    # name the one that applied.
    context "when the handle is rejected" do
      it "says it is reserved" do
        update_with("admin")

        expect(user.reload.name).not_to eq "admin"
        expect(flash[:alert]).to include("ハンドル")
      end

      it "says it is malformed" do
        update_with("not a handle")

        expect(flash[:alert]).to include("ハンドル")
      end

      it "says it is taken" do
        FactoryBot.create(:user, name: "taken-one")

        update_with("taken-one")

        expect(flash[:alert]).to include("ハンドル")
      end
    end
  end
end
