class Admin::SponsorQrCodesController < AdminController
  def index
    @event = OngoingEvent.first!.event
    @sponsors = SponsorCatalog.with_booth(@event.slug).map do |sponsor|
      sponsor.merge(stamp_url: SponsorVisitToken.stamp_url(event_slug: @event.slug, sponsor_key: sponsor.fetch(:key)))
    end
    # Not build_sponsor_booth_qr_card_template, which would detach an existing template from the event.
    @template = @event.sponsor_booth_qr_card_template || SponsorBoothQrCardTemplate.new(event: @event)
  end
end
