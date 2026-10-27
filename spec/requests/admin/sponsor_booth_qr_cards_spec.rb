require "rails_helper"

RSpec.describe "Admin::SponsorBoothQrCards", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }
  let(:booth_sponsor) do
    {key: "booth-sponsor.example", name: "Booth Sponsor", plan: "gold", logo: "S999_booth-sponsor.example_gold", booth: true}
  end
  let(:logo_url) { SponsorCatalog.print_logo_url(event.slug, booth_sponsor) }

  before do
    allow(SponsorCatalog).to receive(:available_for_year?).with(event.slug).and_return(true)
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return([booth_sponsor])
  end

  describe "GET /admin/sponsor_booth_qr_cards/:sponsor_key" do
    context "as an organizer" do
      before { sign_in(FactoryBot.create(:user, role: "organizer")) }

      context "with a template" do
        before do
          FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
          stub_request(:get, logo_url)
            .to_return(body: Vips::Image.black(78, 78, bands: 3).write_to_buffer(".png"))
        end

        it "returns the card as a PNG attachment" do
          get admin_sponsor_booth_qr_card_path(booth_sponsor[:key])

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("image/png")
          expect(response.headers["Content-Disposition"])
            .to start_with('attachment; filename="sponsor-booth-qr-card-booth-sponsor.example.png"')
          card = Vips::Image.new_from_buffer(response.body, "")
          expect([card.width, card.height]).to eq([148, 210])
        end

        it "returns the card inline for preview" do
          get admin_sponsor_booth_qr_card_path(booth_sponsor[:key], disposition: "inline")

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Disposition"]).to start_with("inline;")
        end

        it "returns 404 for a sponsor key that is not a booth sponsor" do
          get admin_sponsor_booth_qr_card_path("no-booth.example")

          expect(response).to have_http_status(:not_found)
        end

        it "raises when the logo cannot be fetched" do
          stub_request(:get, logo_url).to_return(status: 500)

          expect { get admin_sponsor_booth_qr_card_path(booth_sponsor[:key]) }.to raise_error(Faraday::ServerError)
        end

        it "raises when the @3x logo does not exist" do
          stub_request(:get, logo_url).to_return(status: 404)

          expect { get admin_sponsor_booth_qr_card_path(booth_sponsor[:key]) }.to raise_error(Faraday::ResourceNotFound)
        end
      end

      it "returns 404 without a template" do
        get admin_sponsor_booth_qr_card_path(booth_sponsor[:key])

        expect(response).to have_http_status(:not_found)
      end

      context "with a selected event" do
        let(:selected_event) { FactoryBot.create(:event) }
        let(:selected_sponsor) { booth_sponsor.merge(key: "selected-sponsor.example", logo: "selected-sponsor") }
        let(:selected_logo_url) { SponsorCatalog.print_logo_url(selected_event.slug, selected_sponsor) }
        let(:selected_template) { FactoryBot.create(:sponsor_booth_qr_card_template, event: selected_event) }
        let(:template_png) { Vips::Image.black(296, 420, bands: 3).write_to_buffer(".png") }

        before do
          selected_template.image.attach(io: StringIO.new(template_png), filename: "selected-template.png", content_type: "image/png")
          FactoryBot.create(:sponsor_booth_qr_card_template, event:)
          allow(SponsorCatalog).to receive(:available_for_year?).with(selected_event.slug).and_return(true)
          allow(SponsorCatalog).to receive(:with_booth).with(selected_event.slug).and_return([selected_sponsor])
          stub_request(:get, selected_logo_url)
            .to_return(body: Vips::Image.black(78, 78, bands: 3).write_to_buffer(".png"))
        end

        it "generates a card using the selected event's template and sponsor" do
          get admin_sponsor_booth_qr_card_path(selected_sponsor[:key], event_id: selected_event.id)

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("image/png")
          card = Vips::Image.new_from_buffer(response.body, "")
          expect([card.width, card.height]).to eq([296, 420])
          expect(a_request(:get, selected_logo_url)).to have_been_made.once
        end
      end

      it "returns 404 for an event without a catalog" do
        selected_event = FactoryBot.create(:event)
        allow(SponsorCatalog).to receive(:available_for_year?).with(selected_event.slug).and_return(false)

        get admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: selected_event.id)

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for an invalid event without using the ongoing event" do
        get admin_sponsor_booth_qr_card_path(booth_sponsor[:key], event_id: "missing")

        expect(response).to have_http_status(:not_found)
      end
    end

    it "redirects a participant" do
      sign_in(FactoryBot.create(:user, role: "participant"))

      get admin_sponsor_booth_qr_card_path(booth_sponsor[:key])

      expect(response).to redirect_to(root_path)
    end

    it "redirects a logged-out user" do
      get admin_sponsor_booth_qr_card_path(booth_sponsor[:key])

      expect(response).to redirect_to(root_path)
    end
  end
end
