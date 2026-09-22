class Admin::SponsorQrCodesController < AdminController
  def index
    @event = OngoingEvent.first!.event
    @sponsors = SponsorCatalog.with_booth(@event.slug).map do |sponsor|
      sponsor.merge(stamp_url: SponsorVisitToken.stamp_url(event_slug: @event.slug, sponsor_key: sponsor.fetch(:key)))
    end
  end
end
