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
      expect(response.body).to include(new_sponsor_stamp_card_stamp_path(event.slug, code: expected_code))
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
        expect(card_button["data-url"]).to eq(admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: event.id))
        expect(card_button["data-filename"]).to eq("sponsor-booth-qr-card-booth-sponsor.example.png")
        expect(card_button["disabled"]).to be_nil
        expect(document.at_css("button[data-action='sponsor-qr-codes#downloadAllCards']")["disabled"]).to be_nil
        expect(document.at_css("a[href='#{admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: event.id, disposition: "inline")}']").text)
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
            "url" => admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: event.id),
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

    context "with stamp counts" do
      let(:organizer) { FactoryBot.create(:user, role: :organizer) }
      let!(:other_event) { FactoryBot.create(:event, slug: "2025", name: "Kaigi on Rails 2025") }
      let(:unvisited_sponsor) { booth_sponsor.merge(key: "unvisited.example", name: "Unvisited Sponsor") }

      before do
        sign_in(organizer)
        allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return([booth_sponsor, unvisited_sponsor])
        FactoryBot.create(:sponsor_visit, user: organizer, event:, sponsor_key: booth_sponsor[:key])
        FactoryBot.create(:sponsor_visit, event:, sponsor_key: booth_sponsor[:key])
        FactoryBot.create(:sponsor_visit, event: other_event, sponsor_key: booth_sponsor[:key])
      end

      it "shows all-event totals, event totals and sponsor counts including organizers and zero counts" do
        get admin_sponsor_qr_codes_path

        document = Nokogiri::HTML(response.body)
        expect(document.at_css('[data-stamp-count="all"]').text).to eq("3")
        expect(document.at_css('[data-stamp-count="event"]').text).to eq("2")
        expect(document.css('[data-stamp-count="sponsor"]').map(&:text)).to eq(["2", "0"])
        expect(document.at_css("select[name='event_id'] option[selected]")["value"]).to eq(event.id.to_s)
      end

      it "offers copying the stamp URL without displaying the long URL as text" do
        get admin_sponsor_qr_codes_path

        document = Nokogiri::HTML(response.body)
        button = document.at_css('[data-action="sponsor-qr-codes#copyUrl"]')
        expect(button.text.strip).to eq("Copy URL")
        expect(button["data-url"]).to eq(SponsorVisitToken.stamp_url(event_slug: event.slug, sponsor_key: booth_sponsor[:key]))
        expect(document.at_css("table").text).not_to include(button["data-url"])
      end

      it "shows recorded sponsor keys and counts when the selected event has no catalog" do
        get admin_sponsor_qr_codes_path(event_id: other_event.id)

        expect(response).to have_http_status(:ok)
        document = Nokogiri::HTML(response.body)
        expect(document.at_css('[data-stamp-count="all"]').text).to eq("3")
        expect(document.at_css('[data-stamp-count="event"]').text).to eq("1")
        expect(document.at_css("tbody tr").text).to include(booth_sponsor[:key])
        expect(document.at_css('[data-stamp-count="sponsor"]').text).to eq("1")
        expect(document.at_css('[data-action="sponsor-qr-codes#copyUrl"]')).to be_nil
        expect(document.at_css('[data-action="sponsor-qr-codes#downloadAll"]')["disabled"]).not_to be_nil
        expect(document.at_css("form[enctype='multipart/form-data']")["action"])
          .to eq(admin_sponsor_booth_qr_card_template_path(event_id: other_event.id))
      end

      it "switches counts, QR URLs and download destinations to the selected event" do
        allow(SponsorCatalog).to receive(:available_for_year?).with(other_event.slug).and_return(true)
        allow(SponsorCatalog).to receive(:with_booth).with(other_event.slug).and_return([booth_sponsor])
        FactoryBot.create(:sponsor_booth_qr_card_template, event: other_event)

        get admin_sponsor_qr_codes_path(event_id: other_event.id)

        document = Nokogiri::HTML(response.body)
        expect(document.at_css('[data-stamp-count="event"]').text).to eq("1")
        expect(document.at_css('[data-action="sponsor-qr-codes#copyUrl"]')["data-url"])
          .to eq(SponsorVisitToken.stamp_url(event_slug: other_event.slug, sponsor_key: booth_sponsor[:key]))
        expect(document.at_css('[data-action="sponsor-qr-codes#downloadCard"]')["data-url"])
          .to eq(admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: other_event.id))
        controller = document.at_css('[data-controller="sponsor-qr-codes"]')
        expect(JSON.parse(controller["data-sponsor-qr-codes-cards-value"]).first.fetch("url"))
          .to eq(admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: other_event.id))
      end

      it "keeps counts for sponsors no longer in the catalog visible" do
        FactoryBot.create(:sponsor_visit, event:, sponsor_key: "removed.example")

        get admin_sponsor_qr_codes_path

        document = Nokogiri::HTML(response.body)
        row = document.css("tbody tr").find { |tr| tr.text.include?("removed.example") }
        expect(row.at_css('[data-stamp-count="sponsor"]').text).to eq("1")
        expect(row.css("button")).to be_empty
        expect(document.at_css('[data-stamp-count="event"]').text).to eq("3")
      end
    end

    it "shows zero totals without any visits" do
      sign_in(FactoryBot.create(:user, role: :organizer))

      get admin_sponsor_qr_codes_path

      document = Nokogiri::HTML(response.body)
      expect(document.css("[data-stamp-count]").map(&:text)).to eq(["0", "0", "0"])
    end

    it "defaults to the latest event when there is no ongoing event" do
      OngoingEvent.destroy_all
      older_event = FactoryBot.create(:event, start_date: event.start_date - 1.year)
      sign_in(FactoryBot.create(:user, role: :organizer))

      get admin_sponsor_qr_codes_path

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css("option[selected]")["value"]).to eq(event.id.to_s)
      expect(document.css("select option").pluck("value")).to eq([event.id, older_event.id].map(&:to_s))
    end

    it "returns not found for an invalid event without falling back to the ongoing event" do
      sign_in(FactoryBot.create(:user, role: :organizer))

      get admin_sponsor_qr_codes_path(event_id: "missing")

      expect(response).to have_http_status(:not_found)
    end

    it "redirects an operator" do
      sign_in(FactoryBot.create(:user, role: :operator))

      get admin_sponsor_qr_codes_path

      expect(response).to redirect_to(root_path)
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
