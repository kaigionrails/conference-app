require "rails_helper"

RSpec.describe "Admin::ProfileBadgesProfiles", type: :request do
  describe "GET /admin/profiles/:profile_id/profile_badges_profiles/new" do
    let(:organizer) { FactoryBot.create(:user, role: :organizer) }
    before { sign_in(organizer) }

    context "profile without images" do
      let(:profile) { FactoryBot.create(:profile) }

      it "shows the default icon" do
        get new_admin_profile_profile_badges_profile_path(profile)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("default_user_icon")
      end
    end
  end
end
