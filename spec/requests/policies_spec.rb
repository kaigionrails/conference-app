require "rails_helper"

RSpec.describe "Policies", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2026") }

  describe "GET /policies" do
    context "not logged in" do
      it "should success" do
        get "/policies"
        expect(response).to have_http_status(:success)
      end
    end

    context "logged in" do
      let!(:user) { FactoryBot.create(:user) }

      before { sign_in(user) }

      it "should success" do
        get "/policies"
        expect(response).to have_http_status(:success)
      end
    end

    context "with locale=ja" do
      it "renders both policies" do
        get "/policies", params: {locale: "ja"}
        expect(response.body).to include('id="privacy"', 'id="terms"')
        expect(response.body).to include("プライバシーポリシー", "利用規約")
        expect(response.body).to include("https://kaigionrails.org/2026/ja/policies/")
      end
    end

    context "with locale=en" do
      it "renders both policies" do
        get "/policies", params: {locale: "en"}
        expect(response.body).to include('id="privacy"', 'id="terms"')
        expect(response.body).to include("Privacy Policy", "Terms of Service")
        expect(response.body).to include("https://kaigionrails.org/2026/policies/")
      end
    end
  end
end
