class Admin::SponsorBoothQrCardsController < AdminController
  # Generates the card on each request. Failures to fetch the logo propagate as 500s and reach Sentry.
  # @rbs return: void
  def show
    event = OngoingEvent.first!.event
    sponsor = SponsorCatalog.with_booth(event.slug).find { |candidate| candidate.fetch(:key) == params[:sponsor_key] }
    raise ActiveRecord::RecordNotFound, "Booth sponsor not found: #{params[:sponsor_key]}" if sponsor.nil?

    template = event.sponsor_booth_qr_card_template
    raise ActiveRecord::RecordNotFound, "Sponsor booth QR card template not uploaded for #{event.slug}" if template.nil?

    send_data SponsorBoothQrCard.generate(template:, sponsor:),
      type: "image/png",
      filename: helpers.sponsor_booth_qr_card_filename(sponsor),
      disposition: (params[:disposition] == "inline") ? :inline : :attachment
  end
end
