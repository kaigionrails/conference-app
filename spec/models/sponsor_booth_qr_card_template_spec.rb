require "rails_helper"

RSpec.describe SponsorBoothQrCardTemplate, type: :model do
  let(:event) { FactoryBot.create(:event) }

  def image_data(width:, height:, format: ".png")
    Vips::Image.black(width, height, bands: 3).write_to_buffer(format)
  end

  def build_with(data:, content_type:, filename: "template")
    template = described_class.new(event: event)
    template.image.attach(io: StringIO.new(data), filename: filename, content_type: content_type)
    template
  end

  describe "content type" do
    it "accepts PNG, JPEG and WebP" do
      {".png" => "image/png", ".jpg" => "image/jpeg", ".webp" => "image/webp"}.each do |format, content_type|
        template = build_with(data: image_data(width: 148, height: 210, format: format), content_type: content_type)
        expect(template).to be_valid, "expected #{content_type} to be valid: #{template.errors.full_messages}"
      end
    end

    it "rejects other content types" do
      template = build_with(data: "not an image", content_type: "text/plain", filename: "template.txt")

      expect(template).not_to be_valid
      expect(template.errors[:image]).to include("content type text/plain is not allowed")
    end
  end

  describe "aspect ratio" do
    it "accepts the A5 portrait ratio used by the 2026 template" do
      expect(build_with(data: image_data(width: 1748, height: 2480), content_type: "image/png")).to be_valid
    end

    it "accepts a ratio within 1% of A5" do
      # 148:210 = 0.7048; 150 / 210 = 0.7143 is outside, 149 / 210 = 0.7095 is within 1%
      expect(build_with(data: image_data(width: 149, height: 210), content_type: "image/png")).to be_valid
      expect(build_with(data: image_data(width: 150, height: 210), content_type: "image/png")).not_to be_valid
    end

    it "rejects a landscape image" do
      template = build_with(data: image_data(width: 2480, height: 1748), content_type: "image/png")

      expect(template).not_to be_valid
      expect(template.errors[:image]).to include("must be A5 portrait (148:210), got 2480x1748")
    end

    it "rejects a square image" do
      expect(build_with(data: image_data(width: 200, height: 200), content_type: "image/png")).not_to be_valid
    end

    it "rejects a template with bleed" do
      # 154 x 216 mm (A5 with 3 mm bleed) at 300 dpi
      expect(build_with(data: image_data(width: 1819, height: 2551), content_type: "image/png")).not_to be_valid
    end

    it "rejects data that cannot be read as an image" do
      template = build_with(data: "\x89PNG\r\n\x1a\nbroken".b, content_type: "image/png", filename: "template.png")

      expect(template).not_to be_valid
      expect(template.errors[:image]).to include("could not be read as an image")
    end

    it "does not read the stored image again when the attachment is unchanged" do
      template = FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
      reloaded = described_class.find(template.id)

      expect(Vips::Image).not_to receive(:new_from_file)
      expect(Vips::Image).not_to receive(:new_from_buffer)
      expect(reloaded).to be_valid
    end

    it "checks an existing blob attached by signed id" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image_data(width: 2480, height: 1748)), filename: "landscape.png", content_type: "image/png"
      )
      template = described_class.new(event: event)
      template.image.attach(blob.signed_id)

      expect(template).not_to be_valid
      expect(template.errors[:image]).to include("must be A5 portrait (148:210), got 2480x1748")
    end
  end

  it "requires an image" do
    template = described_class.new(event: event)

    expect(template).not_to be_valid
    expect(template.errors[:image]).to be_present
  end

  it "allows only one template per event" do
    FactoryBot.create(:sponsor_booth_qr_card_template, event: event)
    duplicate = FactoryBot.build(:sponsor_booth_qr_card_template, event: event)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:event_id]).to be_present
  end

  it "is destroyed with its event" do
    FactoryBot.create(:sponsor_booth_qr_card_template, event: event)

    expect { event.destroy! }.to change(described_class, :count).by(-1)
  end
end
