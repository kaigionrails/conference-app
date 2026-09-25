require "rails_helper"

RSpec.describe "Admin::SponsorQrCodes", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }
  let(:booth_sponsor) { {key: "booth-sponsor.example", name: "Booth Sponsor", plan: "gold", logo: "booth-sponsor", booth: true} }

  before do
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return([booth_sponsor])
  end

  describe "GET /admin/sponsor_qr_codes" do
    it "shows stamp URLs for booth sponsors to an organizer" do
      sign_in(FactoryBot.create(:user, role: "organizer"))

      get admin_sponsor_qr_codes_path

      expected_code = SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: booth_sponsor[:key])
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Booth Sponsor")
      expect(response.body).to include(new_sponsor_passport_stamp_path(event.slug, code: expected_code))
    end

    it "redirects a participant" do
      sign_in(FactoryBot.create(:user, role: "participant"))

      get admin_sponsor_qr_codes_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects a logged-out user" do
      get admin_sponsor_qr_codes_path

      expect(response).to redirect_to(root_path)
    end
  end
end
