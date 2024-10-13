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

  describe "POST /users" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }

    before do
      sign_in(user)
    end

    context "with valid params" do
      create_param = {
        user: {name: "new_user", role: "operator"},
        auth: {email: "test@example.invalid", password: "password", password_confirmation: "password"} # weakness!
      }
      it "should create new operator role user" do
        expect {
          post admin_users_path, params: create_param
        }.to change { User.operator.count }.by(1).and change { AuthenticationProviderEmailAndPassword.count }.by(1)
      end
    end

    context "with organizer role params" do
      create_param = {
        user: {name: "new_user", role: "organizer"},
        auth: {email: "test@example.invalid", password: "password", password_confirmation: "password"}
      }
      it "should create new operator role user, not organizer role" do
        expect {
          post admin_users_path, params: create_param
        }.to change {
          User.operator.count
        }.by(1).and change {
          AuthenticationProviderEmailAndPassword.count
        }.by(1).and change {
          User.organizer.count
        }.by(0)
      end
    end

    context "with invalid params" do
      create_param = {
        user: {name: "new_user", role: "organizer"},
        auth: {email: "test@example.invalid", password: "password", password_confirmation: "wrong_password"}
      }
      it "should not create new operator" do
        expect {
          post admin_users_path, params: create_param
        }.to change {
          User.operator.count
        }.by(0).and change {
          AuthenticationProviderEmailAndPassword.count
        }.by(0)
      end
    end

    context "already registered email" do
      let(:user) { FactoryBot.create(:user) }
      let!(:authentication_provider_email_and_password) { FactoryBot.create(:authentication_provider_email_and_password, user: user, email: "test@example.invalid") }
      create_param = {
        user: {name: "new_user", role: "organizer"},
        auth: {email: "test@example.invalid", password: "password", password_confirmation: "password"}
      }
      it "should not create new operator" do
        expect {
          post admin_users_path, params: create_param
        }.to change {
          User.operator.count
        }.by(0).and change {
          AuthenticationProviderEmailAndPassword.count
        }.by(0)
      end
    end
  end
end
