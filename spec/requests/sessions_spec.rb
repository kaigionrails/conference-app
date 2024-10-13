require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /auth/email (email and password authentication)" do
    let!(:operator) { FactoryBot.create(:user, role: :operator) }
    let!(:auth) {
      FactoryBot.create(
        :authentication_provider_email_and_password, user: operator, email: "sample@email.invalid", password: "password", password_confirmation: "password"
      )
    }

    context "given valid email and password" do
      it "should not success to login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password"}
        expect(response).to redirect_to(setting_path)
        expect(session[:user_id]).to eq operator.id
      end
    end

    context "given return_to param" do
      it "should not success to login and redirect to return_to" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: "/2024/talks"}
        expect(response).to redirect_to("/2024/talks?") # empty query string
        expect(session[:user_id]).to eq operator.id
      end
    end

    context "given email not exists" do
      it "should not success to login" do
        post "/auth/email", params: {email: "wrong@email.invalid", password: "password"}
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil
      end
    end

    context "given password is wrong" do
      it "should not success to login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "p@ssw0rd"}
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe "POST /auth/unknown (unknown provider)" do
    it "should not success to login" do
      post "/auth/unknown"
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /logout" do
    let!(:user) { FactoryBot.create(:user) }
    before { sign_in(user) }

    it "should logout" do
      get "/logout"
      expect(response).to redirect_to(about_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
