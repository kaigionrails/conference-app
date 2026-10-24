require "rails_helper"

RSpec.describe "Admin::StampRallies", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }
  let(:organizer) { FactoryBot.create(:user, role: :organizer) }
  let(:booth_sponsor) { {key: "booth-sponsor.example", name: "Booth Sponsor", plan: "gold", logo: "booth-sponsor", booth: true} }

  before do
    allow(SponsorCatalog).to receive(:available_for_year?).with(event.slug).and_return(true)
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return([booth_sponsor])
  end

  describe "GET /admin/stamp_rallies" do
    context "as an organizer" do
      before { sign_in(organizer) }

      it "accepts an event without stamps or a card template" do
        get admin_stamp_rallies_path

        expect(response).to have_http_status(:ok)
      end

      it "accepts an event with a card template" do
        FactoryBot.create(:sponsor_booth_qr_card_template, event:)

        get admin_stamp_rallies_path

        expect(response).to have_http_status(:ok)
      end

      it "accepts visits from multiple users and events" do
        FactoryBot.create(:sponsor_visit, user: organizer, event:, sponsor_key: booth_sponsor[:key])
        FactoryBot.create(:sponsor_visit, event:, sponsor_key: booth_sponsor[:key])
        FactoryBot.create(:sponsor_visit, sponsor_key: booth_sponsor[:key])

        get admin_stamp_rallies_path

        expect(response).to have_http_status(:ok)
      end

      it "accepts a selected event without catalog data" do
        archived_event = FactoryBot.create(:event)
        allow(SponsorCatalog).to receive(:available_for_year?).with(archived_event.slug).and_return(false)
        FactoryBot.create(:sponsor_visit, event: archived_event)

        get admin_stamp_rallies_path(event_id: archived_event.id)

        expect(response).to have_http_status(:ok)
      end

      it "accepts records for sponsors no longer in the catalog" do
        FactoryBot.create(:sponsor_visit, event:, sponsor_key: "removed.example")

        get admin_stamp_rallies_path

        expect(response).to have_http_status(:ok)
      end

      context "without an ongoing event" do
        let!(:event) { FactoryBot.create(:event) }

        it "accepts the request" do
          get admin_stamp_rallies_path

          expect(response).to have_http_status(:ok)
        end
      end

      it "returns not found for an invalid event" do
        get admin_stamp_rallies_path(event_id: "missing")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as an operator" do
      before { sign_in(FactoryBot.create(:user, role: :operator)) }

      it "redirects to the root page" do
        get admin_stamp_rallies_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "as a participant" do
      before { sign_in(FactoryBot.create(:user, role: :participant)) }

      it "redirects to the root page" do
        get admin_stamp_rallies_path

        expect(response).to redirect_to(root_path)
      end
    end

    it "redirects a logged-out user" do
      get admin_stamp_rallies_path

      expect(response).to redirect_to(root_path)
    end
  end
end
