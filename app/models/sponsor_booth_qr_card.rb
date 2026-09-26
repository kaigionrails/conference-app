# A printable A5 card for a sponsor booth: the sponsor logo and the stamp QR code composited onto
# the event's SponsorBoothQrCardTemplate.
class SponsorBoothQrCard
  # The layout is in pixels of a 1748x2480 (A5 at 300 dpi) template and is scaled by the template width.
  # It fits the white panel of the 2026 template (x 208-1540, y 568-2184). The QR code sits beside the
  # Hachiko illustration in the lower right corner (from x 1260), leaving a 42px gap.
  BASE_WIDTH = 1748 #: Integer
  LOGO_SIZE = 689 #: Integer
  LOGO_TOP = 657 #: Integer
  # The same size as the logo. 689px is 53 modules (version 7 with the quiet zone) of 13px each.
  QR_MAX_SIZE = LOGO_SIZE #: Integer
  QR_TOP = 1406 #: Integer
  # Nothing is drawn over the QR code, so level M is enough and keeps the modules large.
  QR_LEVEL = :m #: Symbol
  QR_QUIET_ZONE = 4 #: Integer
  A5_WIDTH_MM = 148.0 #: Float
  LOGO_FETCH_TIMEOUTS = {open_timeout: 10, timeout: 30}.freeze #: Hash[Symbol, Integer]

  # @rbs @template: String
  # @rbs @logo: String
  # @rbs @stamp_url: String

  # Downloads the template, fetches the @3x logo from the official site and returns the card as PNG.
  # @rbs template: SponsorBoothQrCardTemplate
  # @rbs sponsor: Hash[Symbol, untyped]
  # @rbs return: String
  def self.generate(template:, sponsor:)
    event_slug = template.event.slug
    new(
      template: template.image.download,
      logo: fetch_logo(SponsorCatalog.print_logo_url(event_slug, sponsor)),
      stamp_url: SponsorVisitToken.stamp_url(event_slug:, sponsor_key: sponsor.fetch(:key))
    ).to_png
  end

  # @rbs url: String
  # @rbs return: String
  def self.fetch_logo(url)
    Faraday.new(request: LOGO_FETCH_TIMEOUTS) { |builder| builder.response :raise_error }.get(url).body
  end
  private_class_method :fetch_logo

  # @rbs template: String -- binary of the template image
  # @rbs logo: String -- binary of the logo image
  # @rbs stamp_url: String -- URL encoded into the QR code
  # @rbs return: void
  def initialize(template:, logo:, stamp_url:)
    @template = template
    @logo = logo
    @stamp_url = stamp_url
  end

  # @rbs return: String
  def to_png
    canvas = normalize(Vips::Image.new_from_buffer(@template, ""))
    scale = canvas.width / BASE_WIDTH.to_f
    logo_box = (LOGO_SIZE * scale).round
    logo = logo_image(logo_box)
    qr = qr_image((QR_MAX_SIZE * scale).floor)
    # Set the resolution from the width so that the card prints at the A5 size whatever the template says.
    resolution = canvas.width / A5_WIDTH_MM

    canvas
      .insert(logo, (canvas.width - logo.width) / 2, (LOGO_TOP * scale).round + (logo_box - logo.height) / 2)
      .insert(qr, (canvas.width - qr.width) / 2, (QR_TOP * scale).round)
      .copy(xres: resolution, yres: resolution)
      .write_to_buffer(".png")
  end

  # Brings any input to 8-bit sRGB with 3 bands. Transparent areas become white, the color of the paper.
  # @rbs image: Vips::Image
  # @rbs return: Vips::Image
  private def normalize(image)
    image = image.autorot
    if image.interpretation == :cmyk && image.get_typeof("icc-profile-data") != 0
      image = image.icc_transform("srgb")
    elsif image.interpretation != :srgb
      # Drop the source profile, which no longer describes the converted pixels.
      image = image.colourspace(:srgb).mutate { |mutable| mutable.remove!("icc-profile-data") }
    end
    image = image.flatten(background: [255, 255, 255]) if image.has_alpha?
    image.cast(:uchar)
  end

  # @rbs box: Integer -- side of the square the logo is fitted into
  # @rbs return: Vips::Image
  private def logo_image(box)
    logo = normalize(Vips::Image.new_from_buffer(@logo, ""))
    logo.resize(box / [logo.width, logo.height].max.to_f)
  end

  # @rbs max_size: Integer -- maximum side of the QR code including the quiet zone
  # @rbs return: Vips::Image
  private def qr_image(max_size)
    code = QRCode::Encoder::Code.build(@stamp_url, level: QR_LEVEL)
    side = code.module_count + QR_QUIET_ZONE * 2
    cell = [max_size / side, 1].max
    rows = code.modules.map { |row| row.map { |dark| dark ? 0 : 255 } }

    Vips::Image.new_from_array(rows)
      .cast(:uchar)
      .embed(QR_QUIET_ZONE, QR_QUIET_ZONE, side, side, extend: :white)
      .resize(cell, kernel: :nearest)
  end
end
