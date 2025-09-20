require "rails_helper"

RSpec.describe "LiveStreams", type: :request do
  describe "GET /:event_slug/live" do
    context "when event not found" do
      let(:user) { FactoryBot.create(:user, role: "organizer") }
      before { sign_in user }
      it "returns 404" do
        get "/1999/live"
        expect(response).to have_http_status(404)
      end
    end

    context "when event found" do
      let(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event, slug: "2025") }

      context "when not logged in" do
        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
        end
      end

      context "when logged in but have not ticket" do
        before do
          sign_in user
        end

        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
        end
      end

      context "when logged in and have ticket" do
        let!(:tito_ticket) { FactoryBot.create(:tito_ticket, user: user, event: event, state: "complete") }
        before do
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end

      context "when logged in and organizer" do
        before do
          user.update(role: "organizer")
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
