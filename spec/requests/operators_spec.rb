require "rails_helper"

RSpec.describe "Operators", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }

  describe "GET /index" do
    context "not logged in" do
      it "should redirect to /about" do
        get "/operators"
        expect(response).to redirect_to(login_path)
      end
    end

    context "user is participant" do
      let(:user) { FactoryBot.create(:user, role: :participant) }
      before { sign_in(user) }

      it "should redirect to /about" do
        get "/operators"
        expect(response).to redirect_to(about_path)
      end
    end

    context "user is operator" do
      let(:user) { FactoryBot.create(:user, role: :operator) }
      before { sign_in(user) }

      it "should success" do
        get "/operators"
        expect(response).to have_http_status(:success)
      end
    end

    context "user is organizer" do
      let(:user) { FactoryBot.create(:user, role: :organizer) }
      before { sign_in(user) }

      it "should success" do
        get "/operators"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
