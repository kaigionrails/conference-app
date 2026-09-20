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
      it "should success to login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password"}
        expect(response).to redirect_to(operators_path)
        expect(session[:user_id]).to eq operator.id
      end
    end

    context "given return_to param" do
      it "should login and redirect to return_to" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: "/2024/talks"}
        expect(response).to redirect_to("/2024/talks")
        expect(session[:user_id]).to eq operator.id
      end

      it "keeps the query string" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: "/@foo?token=abc"}
        expect(response).to redirect_to("/@foo?token=abc")
      end

      # Only the path and query are used, so a value naming another host is
      # stripped down to its path rather than rejected.
      context "given a return_to naming another host" do
        {"https://evil.com/x" => "/x", "//evil.com/steal" => "/steal"}.each do |value, expected|
          it "redirects to #{expected} for #{value.inspect}" do
            post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: value}
            expect(response).to redirect_to(expected)
          end
        end
      end

      # These have no usable path: "////evil.com" keeps its slashes and would
      # be a protocol-relative redirect, the others do not parse into one.
      context "given a return_to with no path on this site" do
        ["////evil.com", "javascript:alert(1)", "/\\evil.com", ""].each do |value|
          it "falls back to the default for #{value.inspect}" do
            post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: value}
            expect(response).to redirect_to(operators_path)
            expect(session[:user_id]).to eq operator.id
          end
        end
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

  describe "login attempt limit" do
    include ActiveSupport::Testing::TimeHelpers

    let!(:operator) { FactoryBot.create(:user, role: :operator) }
    let!(:auth) {
      FactoryBot.create(
        :authentication_provider_email_and_password, user: operator, email: "sample@email.invalid", password: "password", password_confirmation: "password"
      )
    }

    def fail_login
      post "/auth/email", params: {email: "sample@email.invalid", password: "wrong"}
    end

    def succeed_login
      post "/auth/email", params: {email: "sample@email.invalid", password: "password"}
    end

    it "rejects further attempts once the limit is reached" do
      Authentication::LOGIN_ATTEMPT_LIMIT.times { fail_login }

      succeed_login
      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
    end

    it "still allows a login just below the limit" do
      (Authentication::LOGIN_ATTEMPT_LIMIT - 1).times { fail_login }

      succeed_login
      expect(session[:user_id]).to eq operator.id
    end

    it "resets the count after a successful login" do
      (Authentication::LOGIN_ATTEMPT_LIMIT - 1).times { fail_login }
      succeed_login
      (Authentication::LOGIN_ATTEMPT_LIMIT - 1).times { fail_login }

      succeed_login
      expect(session[:user_id]).to eq operator.id
    end

    it "forgets the attempts once the window passes" do
      Authentication::LOGIN_ATTEMPT_LIMIT.times { fail_login }

      travel(Authentication::LOGIN_ATTEMPT_PERIOD + 1.minute) do
        succeed_login
        expect(session[:user_id]).to eq operator.id
      end
    end
  end

  describe "POST /auth/unknown (unknown provider)" do
    it "should not success to login" do
      post "/auth/unknown"
      expect(response).to redirect_to(login_path)
    end
  end

  describe "DELETE /logout" do
    let!(:user) { FactoryBot.create(:user) }

    it "should logout" do
      sign_in_through_github(user)
      expect(session[:user_id]).to eq user.id

      delete "/logout"
      expect(response).to redirect_to(about_path)
      expect(session[:user_id]).to be_nil
    end

    # GET is reachable by prefetch and by an <img> on another site, and carries
    # no CSRF token.
    it "is not reachable with GET" do
      sign_in_through_github(user)

      get "/logout"
      expect(response).to have_http_status(:not_found)
      expect(session[:user_id]).to eq user.id
    end
  end
end
