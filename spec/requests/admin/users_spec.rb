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

      context "with a role filter" do
        before do
          FactoryBot.create(:user, role: :organizer, name: "filtered_organizer")
          FactoryBot.create(:user, role: :operator, name: "filtered_operator")
        end

        it "filters users by role" do
          get admin_users_path, params: {role: "operator"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("filtered_operator")
          expect(response.body).not_to include("filtered_organizer")
          expect(response.body).not_to include("sample_user_1")
        end
      end

      context "with a name filter" do
        before do
          FactoryBot.create(:user, name: "other_user")
        end

        it "filters users by name prefix" do
          get admin_users_path, params: {name: "sample_user"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("sample_user_1")
          expect(response.body).to include("sample_user_2")
          expect(response.body).to include("sample_user_3")
          expect(response.body).not_to include("other_user")
        end
      end

      context "with name and role filters" do
        before do
          FactoryBot.create(:user, name: "sample_operator", role: :operator)
          FactoryBot.create(:user, name: "other_operator", role: :operator)
        end

        it "filters users by both name and role" do
          get admin_users_path, params: {name: "sample", role: "operator"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("sample_operator")
          expect(response.body).not_to include("sample_user_1", "other_operator")
        end
      end

      context "with an invalid role" do
        before do
          FactoryBot.create(:user, name: "listed_organizer", role: :organizer)
          FactoryBot.create(:user, name: "listed_operator", role: :operator)
        end

        it "shows the normal user list for an invalid role" do
          get admin_users_path, params: {role: "invalid"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("sample_user_1", "sample_user_2", "sample_user_3", "listed_organizer", "listed_operator")
        end
      end

      context "with a name filter and an invalid role" do
        before do
          FactoryBot.create(:user, name: "other_user")
        end

        it "still filters by name when the role is invalid" do
          get admin_users_path, params: {name: "sample", role: "invalid"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("sample_user_1")
          expect(response.body).not_to include("other_user")
        end
      end

      context "with an empty name and a role filter" do
        before do
          FactoryBot.create(:user, name: "listed_operator", role: :operator)
        end

        it "keeps the role filter when the name search is cleared" do
          get admin_users_path, params: {name: "", role: "operator"}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("listed_operator")
          expect(response.body).not_to include("sample_user_1")
        end
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
