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

    context "when event found and ongoing" do
      let(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2025", end_date: 1.minutes.since) }

      context "when not logged in" do
        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in but have not ticket" do
        before do
          sign_in user
        end

        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
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

        it "passes the YOYO Translate URLs of the event to the page" do
          FactoryBot.create(:yoyo_translate_setting, event: event)

          get "/2025/live"

          expect(response.body).to include('data-live-streams-yoyo-translate-magenta-hall-url-value="https://example.com/magenta"')
          expect(response.body).to include('data-live-streams-yoyo-translate-lime-hall-url-value="https://example.com/lime"')
        end

        it "passes empty YOYO Translate URLs without the setting" do
          get "/2025/live"

          expect(response.body).to include('data-live-streams-yoyo-translate-magenta-hall-url-value=""')
          expect(response.body).to include('data-live-streams-yoyo-translate-lime-hall-url-value=""')
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

      context "when logged in an operator" do
        before do
          user.update(role: "operator")
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when event found but over" do
      let(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2025", end_date: 1.minute.ago) }

      context "when not logged in" do
        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in but have not ticket" do
        before do
          sign_in user
        end

        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in and have ticket" do
        let!(:tito_ticket) { FactoryBot.create(:tito_ticket, user: user, event: event, state: "complete") }
        before do
          sign_in user
        end

        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
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

      context "when logged in an operator" do
        before do
          user.update(role: "operator")
          sign_in user
        end

        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
        end
      end
    end
  end
end
