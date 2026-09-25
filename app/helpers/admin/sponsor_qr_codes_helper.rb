module Admin::SponsorQrCodesHelper
  def sponsor_qr_filename(sponsor)
    "sponsor-qr-#{sponsor.fetch(:key).gsub(/[^a-zA-Z0-9._-]/, "-")}.png"
  end

  def sponsor_qr_downloads(sponsors)
    sponsors.map { |sponsor| {url: sponsor.fetch(:stamp_url), filename: sponsor_qr_filename(sponsor)} }
  end
end
