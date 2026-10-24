class Admin::SponsorQrCodesController < AdminController
  def index
    @event = if params[:event_id].present?
      Event.find(params[:event_id])
    else
      OngoingEvent.first&.event || Event.order(start_date: :desc, id: :desc).first!
    end

    @events = Event.order(start_date: :desc, id: :desc)
    @total_stamp_count = SponsorVisit.count
    @event_stamp_count = @event.sponsor_visits.count
    @sponsor_stamp_counts = @event.sponsor_visits.group(:sponsor_key).count
    sponsors = [] #: Array[Hash[Symbol, untyped]]
    sponsors = SponsorCatalog.with_booth(@event.slug) if SponsorCatalog.available_for_year?(@event.slug)
    @sponsors = sponsors.map do |sponsor|
      sponsor.merge(stamp_url: SponsorVisitToken.stamp_url(event_slug: @event.slug, sponsor_key: sponsor.fetch(:key)))
    end
    @qr_sponsors = @sponsors.dup
    missing_keys = @sponsor_stamp_counts.keys - sponsors.pluck(:key)
    @sponsors.concat(missing_keys.sort.map { |key| {key:, name: key, plan: "", stamp_url: nil} })
    # Not build_sponsor_booth_qr_card_template, which would detach an existing template from the event.
    @template = @event.sponsor_booth_qr_card_template || SponsorBoothQrCardTemplate.new(event: @event)
  end
end
