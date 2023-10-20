require 'rails_helper'

RSpec.describe "Admin", type: :request do
  describe "GET /index" do
    context "not logged in" do
      it "redirect to root path" do
        get admin_path
        expect(response).to redirect_to(root_path)
        expect(response.body).not_to include("ConferenceApp Admin")
      end
    end

    context "user is a participant" do
      let(:user) { FactoryBot.create(:user, role: :participant) }

      before { sign_in(user) }

      it "redirect to root path" do
        get admin_path
        expect(response).to redirect_to(root_path)
        expect(response.body).not_to include("ConferenceApp Admin")
      end
    end

    context "user is an organizer" do
      let(:user) { FactoryBot.create(:user, role: :organizer) }

      before { sign_in(user) }

      it "returns http success" do
        get admin_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("ConferenceApp Admin")
      end
    end
  end
end
