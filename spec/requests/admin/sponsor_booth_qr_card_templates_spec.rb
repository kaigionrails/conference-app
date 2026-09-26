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
        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

        expect(response).to redirect_to(admin_sponsor_qr_codes_path)
        expect(flash[:success]).to eq("Booth QR card template uploaded")
        expect(event.reload.sponsor_booth_qr_card_template.image).to be_attached
      end

      it "replaces the image of an existing template" do
        template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = template.image.blob

        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480, filename: "new.png")}}

        expect(response).to redirect_to(admin_sponsor_qr_codes_path)
        expect(SponsorBoothQrCardTemplate.count).to eq(1)
        expect(template.reload.image.blob).not_to eq(old_blob)
        expect(template.image.filename.to_s).to eq("new.png")
      end

      it "rejects an image that is not A5 portrait and keeps the current one" do
        template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
        old_blob = template.image.blob

        patch admin_sponsor_booth_qr_card_template_path,
          params: {sponsor_booth_qr_card_template: {image: upload(width: 2480, height: 1748)}}

        expect(response).to redirect_to(admin_sponsor_qr_codes_path)
        expect(flash[:alert]).to include("must be A5 portrait (148:210), got 2480x1748")
        expect(template.reload.image.blob).to eq(old_blob)
      end

      it "reports a missing file instead of failing with 400" do
        patch admin_sponsor_booth_qr_card_template_path, params: {}

        expect(response).to redirect_to(admin_sponsor_qr_codes_path)
        expect(flash[:alert]).to be_present
        expect(SponsorBoothQrCardTemplate.count).to eq(0)
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
      expect(SponsorBoothQrCardTemplate.count).to eq(0)
    end

    it "redirects a logged-out user" do
      patch admin_sponsor_booth_qr_card_template_path,
        params: {sponsor_booth_qr_card_template: {image: upload(width: 1748, height: 2480)}}

      expect(response).to redirect_to(root_path)
      expect(SponsorBoothQrCardTemplate.count).to eq(0)
    end
  end
end
