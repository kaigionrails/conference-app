require "rails_helper"

RSpec.describe "Admin::SponsorBoothQrCardTemplates", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }

  def upload(width:, height:, filename: "template.png")
    png = Vips::Image.black(width, height, bands: 3).write_to_buffer(".png")
    Rack::Test::UploadedFile.new(StringIO.new(png), "image/png", original_filename: filename)
  end

  describe "PATCH /admin/sponsor_booth_qr_card_template" do
    context "as an organizer" do
      before { sign_in(FactoryBot.create(:user, role: "organizer")) }

      it "creates the template of the ongoing event" do
        newer_event = FactoryBot.create(:event, start_date: event.start_date + 1.year)

        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

        expect(response).to redirect_to(admin_stamp_rallies_path)
        expect(event.reload.sponsor_booth_qr_card_template.image).to be_attached
        expect(newer_event.reload.sponsor_booth_qr_card_template).to be_nil
      end

      context "without an ongoing event" do
        let!(:event) { FactoryBot.create(:event) }

        it "uses the latest event" do
          latest_event = FactoryBot.create(:event, start_date: event.start_date + 1.year)

          patch admin_sponsor_booth_qr_card_template_path,
            params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

          expect(response).to redirect_to(admin_stamp_rallies_path)
          expect(latest_event.reload.sponsor_booth_qr_card_template.image).to be_attached
          expect(event.reload.sponsor_booth_qr_card_template).to be_nil
        end
      end

      it "replaces the image of an existing template" do
        template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = template.image.blob

        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480, filename: "new.png")}}

        expect(response).to redirect_to(admin_stamp_rallies_path)
        expect(event.reload.sponsor_booth_qr_card_template).to eq(template)
        expect(template.reload.image.blob).not_to eq(old_blob)
        expect(template.image.filename.to_s).to eq("new.png")
      end

      it "uploads to the selected event and keeps that event selected after redirecting" do
        selected_event = FactoryBot.create(:event)
        ongoing_template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = ongoing_template.image.blob

        patch admin_sponsor_booth_qr_card_template_path(event_id: selected_event.id),
          params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

        expect(response).to redirect_to(admin_stamp_rallies_path(event_id: selected_event.id))
        expect(selected_event.reload.sponsor_booth_qr_card_template.image).to be_attached
        expect(ongoing_template.reload.image.blob).to eq(old_blob)
      end

      it "keeps the selected event after an invalid upload" do
        selected_event = FactoryBot.create(:event)

        patch admin_sponsor_booth_qr_card_template_path(event_id: selected_event.id), params: {}

        expect(response).to redirect_to(admin_stamp_rallies_path(event_id: selected_event.id))
        expect(flash[:alert]).to be_present
        expect(selected_event.reload.sponsor_booth_qr_card_template).to be_nil
      end

      it "returns not found for an invalid event without updating the ongoing event" do
        expect do
          patch admin_sponsor_booth_qr_card_template_path(event_id: "missing"),
            params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}
        end.not_to change(SponsorBoothQrCardTemplate, :count)

        expect(response).to have_http_status(:not_found)
      end

      it "rejects an image that is not A5 portrait and keeps the current one" do
        template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = template.image.blob

        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 2480, height: 1748)}}

        expect(response).to redirect_to(admin_stamp_rallies_path)
        expect(flash[:alert]).to be_present
        expect(template.reload.image.blob).to eq(old_blob)
      end

      it "reports a missing file instead of failing with 400" do
        patch admin_sponsor_booth_qr_card_template_path, params: {}

        expect(response).to redirect_to(admin_stamp_rallies_path)
        expect(flash[:alert]).to be_present
        expect(event.reload.sponsor_booth_qr_card_template).to be_nil
      end

      it "keeps the current image when no file is sent" do
        template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = template.image.blob

        patch admin_sponsor_booth_qr_card_template_path, params: {}

        expect(flash[:alert]).to be_present
        expect(template.reload.image.blob).to eq(old_blob)
      end
    end

    it "redirects a participant" do
      sign_in(FactoryBot.create(:user, role: "participant"))

      patch admin_sponsor_booth_qr_card_template_path,
        params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

      expect(response).to redirect_to(root_path)
      expect(event.reload.sponsor_booth_qr_card_template).to be_nil
    end

    it "redirects a logged-out user" do
      patch admin_sponsor_booth_qr_card_template_path,
        params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

      expect(response).to redirect_to(root_path)
      expect(event.reload.sponsor_booth_qr_card_template).to be_nil
    end
  end
end
