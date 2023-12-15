require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  before do
    FactoryBot.create(:user, :with_profile_image, name: "sample_user_1")
    FactoryBot.create(:user, :with_profile_image, name: "sample_user_2")
    FactoryBot.create(:user, :with_profile_image, name: "sample_user_3")
  end

  describe "GET /index" do
    context "user is not an organizer" do
      let(:user) { FactoryBot.create(:user, role: :participant) }
      before { sign_in(user) }
      it "redirect to root path" do
        get admin_users_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "user is an organizer" do
      let(:user) { FactoryBot.create(:user, role: :organizer) }
      before { sign_in(user) }
      it "shows users list table" do
        get admin_users_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Users")
        expect(response.body).to include("sample_user_1")
      end
    end
  end

  describe "GET /users/:id" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }

    before do
      sign_in(user)
    end

    let(:target_user) { User.find_by!(name: "sample_user_1") }

    it "shows specific user info" do
      get admin_user_path(target_user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("sample_user_1")
    end
  end

  describe "PATCH /users/:id" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }

    before do
      sign_in(user)
    end

    let(:target_user) { User.find_by!(name: "sample_user_1") }

    it "should update success" do
      update_param = {user: {role: "organizer"}}
      patch admin_user_path(target_user), params: update_param
      expect(response).to have_http_status(:redirect)
      expect(target_user.reload.role).to eq("organizer")
    end
  end
end
