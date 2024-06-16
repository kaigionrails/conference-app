require "rails_helper"

RSpec.describe "Profiles", type: :request do
  before { prepare_current_event }
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
  end
end
