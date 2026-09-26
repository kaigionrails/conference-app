require "rails_helper"

RSpec.describe SponsorBoothQrCard, type: :model do
  let(:stamp_url) { "https://app.example.invalid/sponsor_passports/2026/stamps/new?code=#{"a" * 43}" }
  let(:template_color) { [40, 40, 40] }

  def solid_png(width, height, color)
    Vips::Image.black(width, height, bands: color.size).new_from_image(color).cast(:uchar).write_to_buffer(".png")
  end

  def render(template:, logo: solid_png(780, 780, [255, 0, 0]))
    Vips::Image.new_from_buffer(described_class.new(template:, logo:, stamp_url:).to_png, "")
  end

  def pixel(image, x, y)
    image.getpoint(x, y).map(&:to_i)
  end

  describe "#to_png" do
    subject(:card) { render(template: solid_png(1748, 2480, template_color)) }

    it "keeps the template size as an 8-bit sRGB image" do
      expect([card.width, card.height]).to eq([1748, 2480])
      expect(card.bands).to eq(3)
      expect(card.format).to eq(:uchar)
      expect(card.interpretation).to eq(:srgb)
    end

    it "sets the resolution so that the card prints at the A5 width" do
      expect(card.xres).to be_within(0.001).of(1748 / 148.0)
      expect(card.yres).to be_within(0.001).of(1748 / 148.0)
    end

    it "places the logo in the 689px box centered horizontally at the top offset" do
      # The box spans x 529-1218 and y 657-1346.
      expect(pixel(card, 874, 1001)).to eq([255, 0, 0])
      expect(pixel(card, 530, 658)).to eq([255, 0, 0])
      expect(pixel(card, 1216, 1344)).to eq([255, 0, 0])
      expect(pixel(card, 528, 1001)).to eq(template_color)
      expect(pixel(card, 874, 656)).to eq(template_color)
      expect(pixel(card, 874, 1347)).to eq(template_color)
    end

    it "draws every QR module at the expected position" do
      code = QRCode::Encoder::Code.build(stamp_url, level: :m)
      side = code.module_count + 8
      cell = 689 / side
      size = side * cell
      left = (1748 - size) / 2
      qr = card.crop(left, 1406, size, size).extract_band(0)
      pixels = qr.write_to_memory.unpack("C*")

      code.modules.each_with_index do |row, r|
        row.each_with_index do |dark, c|
          x = (c + 4) * cell + cell / 2
          y = (r + 4) * cell + cell / 2
          expect(pixels[y * size + x]).to eq(dark ? 0 : 255), "module (#{r}, #{c})"
        end
      end
    end

    it "surrounds the QR code with a white quiet zone of 4 modules" do
      code = QRCode::Encoder::Code.build(stamp_url, level: :m)
      side = code.module_count + 8
      cell = 689 / side
      size = side * cell
      left = (1748 - size) / 2
      quiet = 4 * cell

      [
        card.crop(left, 1406, size, quiet),
        card.crop(left, 1406 + size - quiet, size, quiet),
        card.crop(left, 1406, quiet, size),
        card.crop(left + size - quiet, 1406, quiet, size)
      ].each do |band|
        expect(band.min).to eq(255)
      end
      expect(pixel(card, left - 1, 1406 + size / 2)).to eq(template_color)
    end

    it "keeps the aspect ratio of a non-square logo and centers it in the box" do
      card = render(template: solid_png(1748, 2480, template_color), logo: solid_png(400, 200, [255, 0, 0]))

      # 400x200 is resized to 689x345, placed at y 829-1174 inside the 657-1346 box.
      expect(pixel(card, 874, 1001)).to eq([255, 0, 0])
      expect(pixel(card, 874, 700)).to eq(template_color)
      expect(pixel(card, 874, 1300)).to eq(template_color)
    end

    it "converts a grayscale template to sRGB" do
      card = render(template: solid_png(1748, 2480, [40]))

      expect(card.bands).to eq(3)
      expect(card.interpretation).to eq(:srgb)
      expect(pixel(card, 100, 100)).to eq(template_color)
    end

    it "fills transparent areas of the template with white" do
      card = render(template: solid_png(1748, 2480, [40, 40, 40, 0]))

      expect(card.bands).to eq(3)
      expect(pixel(card, 100, 100)).to eq([255, 255, 255])
    end

    it "scales the layout with the template width" do
      card = render(template: solid_png(874, 1240, template_color))

      # The logo box becomes 345px at x 264-609 and y 329-674.
      expect(pixel(card, 437, 501)).to eq([255, 0, 0])
      expect(pixel(card, 437, 328)).to eq(template_color)
      expect(card.xres).to be_within(0.001).of(874 / 148.0)
    end
  end
end
