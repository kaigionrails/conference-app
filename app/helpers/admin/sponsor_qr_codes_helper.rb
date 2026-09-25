module Admin::SponsorQrCodesHelper
  # @rbs! include _RbsRailsPathHelpers

  def sponsor_qr_filename(sponsor)
    "sponsor-qr-#{sanitized_sponsor_key(sponsor)}.png"
  end

  def sponsor_qr_downloads(sponsors)
    sponsors.map { |sponsor| {url: sponsor.fetch(:stamp_url), filename: sponsor_qr_filename(sponsor)} }
  end

  # @rbs sponsor: Hash[Symbol, untyped]
  # @rbs return: String
  def sponsor_booth_qr_card_filename(sponsor)
    "sponsor-booth-qr-card-#{sanitized_sponsor_key(sponsor)}.png"
  end

  # The name is shown when a card cannot be generated while downloading all of them.
  # @rbs sponsors: Array[Hash[Symbol, untyped]]
  # @rbs return: Array[{name: String, url: String, filename: String}]
  def sponsor_booth_qr_card_downloads(sponsors)
    sponsors.map do |sponsor|
      {
        name: sponsor.fetch(:name),
        url: admin_sponsor_booth_qr_card_path(sponsor.fetch(:key)),
        filename: sponsor_booth_qr_card_filename(sponsor)
      }
    end
  end

  # @rbs sponsor: Hash[Symbol, untyped]
  # @rbs return: String
  private def sanitized_sponsor_key(sponsor)
    sponsor.fetch(:key).gsub(/[^a-zA-Z0-9._-]/, "-")
  end
end
