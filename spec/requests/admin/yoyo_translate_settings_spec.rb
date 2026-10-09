require "rails_helper"

RSpec.describe "Admin::YoyoTranslateSettings", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }

  describe "PATCH /admin/yoyo_translate_setting" do
    context "as an organizer" do
      before { sign_in(FactoryBot.create(:user, role: "organizer")) }

      it "creates the setting of the ongoing event" do
        patch admin_yoyo_translate_setting_path,
          params: {yoyo_translate_setting: {magenta_hall_url: "https://example.com/magenta", lime_hall_url: "https://example.com/lime"}}

        expect(response).to redirect_to(admin_live_streams_path)
        setting = event.reload.yoyo_translate_setting
        expect(setting.magenta_hall_url).to eq("https://example.com/magenta")
        expect(setting.lime_hall_url).to eq("https://example.com/lime")
      end

      it "updates the existing setting" do
        setting = FactoryBot.create(:yoyo_translate_setting, event: event)

        patch admin_yoyo_translate_setting_path,
          params: {yoyo_translate_setting: {magenta_hall_url: "https://example.com/new-magenta", lime_hall_url: "https://example.com/new-lime"}}

        expect(response).to redirect_to(admin_live_streams_path)
        expect(YoyoTranslateSetting.count).to eq(1)
        expect(setting.reload.magenta_hall_url).to eq("https://example.com/new-magenta")
        expect(setting.lime_hall_url).to eq("https://example.com/new-lime")
      end

      it "clears the URLs sent blank" do
        setting = FactoryBot.create(:yoyo_translate_setting, event: event)

        patch admin_yoyo_translate_setting_path,
          params: {yoyo_translate_setting: {magenta_hall_url: "", lime_hall_url: ""}}

        expect(response).to redirect_to(admin_live_streams_path)
        expect(setting.reload.magenta_hall_url).to be_nil
        expect(setting.lime_hall_url).to be_nil
      end

      it "re-renders the Live page with the error for a URL that is not https" do
        patch admin_yoyo_translate_setting_path,
          params: {yoyo_translate_setting: {magenta_hall_url: "http://example.com", lime_hall_url: ""}}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Magenta Hall URLは https:// で始まる URL を入力してください")
      end
    end

    it "redirects a participant" do
      sign_in(FactoryBot.create(:user, role: "participant"))

      patch admin_yoyo_translate_setting_path,
        params: {yoyo_translate_setting: {magenta_hall_url: "https://example.com/magenta"}}

      expect(response).to redirect_to(root_path)
      expect(YoyoTranslateSetting.count).to eq(0)
    end

    it "redirects a logged-out user" do
      patch admin_yoyo_translate_setting_path,
        params: {yoyo_translate_setting: {magenta_hall_url: "https://example.com/magenta"}}

      expect(response).to redirect_to(root_path)
      expect(YoyoTranslateSetting.count).to eq(0)
    end
  end
end
