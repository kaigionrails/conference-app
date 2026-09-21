require "rails_helper"

RSpec.describe "LocaleSettings", type: :request do
  # A visitor who is not logged in has nowhere to keep the locale but the
  # query string, so every generated URL has to carry it on.
  describe "carrying ?locale through generated URLs" do
    let!(:event) { FactoryBot.create(:event, slug: "2026", end_date: 1.day.since) }
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }

    it "appends the locale to links" do
      get "/about", params: {locale: "en"}

      expect(response.body).to include("/2026/talks?locale=en")
    end

    it "leaves URLs alone without a locale" do
      get "/about"

      expect(response.body).to include("/2026/talks\"")
      expect(response.body).not_to include("?locale=")
    end

    it "ignores a locale that is not available" do
      get "/about", params: {locale: "xx"}

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("locale=xx")
    end

    it "keeps the locale when a redirect sends the visitor back" do
      post "/2026/live/checkin", params: {tito_ticket_reference: "NOPE-1", locale: "en"}

      expect(response).to redirect_to("/2026/live/checkin?locale=en")
    end
  end

  describe "POST /locale_settings" do
    context "when not logged in" do
      context "switch to en locale" do
        it "should redirect to return_to path with locale query parameter" do
          post "/locale_settings", params: {locale: "en", return_to: "/"}
          expect(response).to redirect_to("/?locale=en")
        end
      end

      context "switch to ja locale" do
        it "should redirect to return_to path with locale query parameter" do
          post "/locale_settings", params: {locale: "ja", return_to: "/"}
          expect(response).to redirect_to("/?locale=ja")
        end
      end
    end

    context "when logged in" do
      let(:user) { FactoryBot.create(:user) }
      before { sign_in(user) }
      context "has no locale_setting" do
        context "switch to en locale" do
          it "should create locale_setting and redirect to return_to path with locale query parameter" do
            expect(user.locale_setting).to eq nil
            post "/locale_settings", params: {locale: "en", return_to: "/"}
            expect(response).to redirect_to("/?locale=en")
            expect(user.reload.locale_setting.preferred_locale).to eq("en")
          end
        end
      end

      context "already has a locale_setting" do
        before do
          LocaleSetting.create!(user: user, preferred_locale: "en")
        end
        it "should create locale_setting and redirect to return_to path with locale query parameter" do
          post "/locale_settings", params: {locale: "ja", return_to: "/"}
          expect(response).to redirect_to("/?locale=ja")
          expect(user.reload.locale_setting.preferred_locale).to eq("ja")
        end
      end
    end
  end
end
