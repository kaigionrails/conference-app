require "rails_helper"

RSpec.describe "Homes", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }

  describe "GET /" do
    context "not logged-in" do
      it "redirect to about page" do
        get "/"
        expect(response).to redirect_to about_path
      end
    end

    context "logged-in" do
      let(:user) { FactoryBot.create(:user) }
      before { sign_in(user) }
      it "returns http success" do
        get "/"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
