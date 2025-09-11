require "rails_helper"

RSpec.describe "LocaleSettings", type: :request do
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
