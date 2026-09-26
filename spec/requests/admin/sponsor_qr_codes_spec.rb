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

    context "with a booth QR card template" do
      before do
        FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        sign_in(FactoryBot.create(:user, role: "organizer"))
      end

      it "offers the card downloads and a preview" do
        get admin_sponsor_qr_codes_path

        document = Nokogiri::HTML(response.body)
        card_button = document.at_css("button[data-action='sponsor-qr-codes#downloadCard']")
        expect(card_button["data-url"]).to eq(admin_sponsor_booth_qr_card_path(booth_sponsor[:key]))
        expect(card_button["data-filename"]).to eq("sponsor-booth-qr-card-booth-sponsor.example.png")
        expect(card_button["disabled"]).to be_nil
        expect(document.at_css("button[data-action='sponsor-qr-codes#downloadAllCards']")["disabled"]).to be_nil
        expect(document.at_css("a[href='#{admin_sponsor_booth_qr_card_path(booth_sponsor[:key], disposition: "inline")}']").text)
          .to eq("Preview")
        expect(response.body).to include("template.png")
        expect(response.body).not_to include("No template uploaded yet.")
      end

      it "passes the cards to the Stimulus controller" do
        get admin_sponsor_qr_codes_path

        controller_element = Nokogiri::HTML(response.body).at_css("[data-controller='sponsor-qr-codes']")
        expect(JSON.parse(controller_element["data-sponsor-qr-codes-cards-value"])).to eq([
          {
            "name" => "Booth Sponsor",
            "url" => admin_sponsor_booth_qr_card_path(booth_sponsor[:key]),
            "filename" => "sponsor-booth-qr-card-booth-sponsor.example.png"
          }
        ])
        expect(controller_element["data-sponsor-qr-codes-card-zip-filename-value"]).to eq("sponsor-booth-qr-cards-2026.zip")
      end
    end

    it "disables the card downloads without a template" do
      sign_in(FactoryBot.create(:user, role: "organizer"))

      get admin_sponsor_qr_codes_path

      document = Nokogiri::HTML(response.body)
      expect(response.body).to include("No template uploaded yet.")
      expect(document.at_css("button[data-action='sponsor-qr-codes#downloadCard']")["disabled"]).to be_present
      expect(document.at_css("button[data-action='sponsor-qr-codes#downloadAllCards']")["disabled"]).to be_present
      expect(document.at_css("a[href*='disposition=inline']")).to be_nil
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
