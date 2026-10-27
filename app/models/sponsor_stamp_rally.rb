class SponsorStampRally
  attr_reader :event #: Event

  # @rbs event: Event
  # @rbs return: void
  def initialize(event:)
    @event = event
  end

  def total_stamp_count
    @total_stamp_count ||= SponsorVisit.count
  end

  def event_stamp_count
    @event_stamp_count ||= event.sponsor_visits.count
  end

  def stamp_count_for(sponsor_key)
    sponsor_stamp_counts.fetch(sponsor_key, 0)
  end

  def sponsors
    @sponsors ||= begin
      missing_keys = sponsor_stamp_counts.keys - qr_sponsors.pluck(:key)
      qr_sponsors + missing_keys.sort.map { |key| {key:, name: key, plan: "", stamp_url: nil} }
    end
  end

  def qr_sponsors
    @qr_sponsors ||= begin
      sponsors = [] #: Array[Hash[Symbol, untyped]]
      sponsors = SponsorCatalog.with_booth(event.slug) if SponsorCatalog.available_for_year?(event.slug)
      sponsors.map do |sponsor|
        sponsor.merge(stamp_url: SponsorVisitToken.stamp_url(event_slug: event.slug, sponsor_key: sponsor.fetch(:key)))
      end
    end
  end

  def template
    # Not event.build_sponsor_booth_qr_card_template, which would detach an existing template.
    @template ||= event.sponsor_booth_qr_card_template || SponsorBoothQrCardTemplate.new(event:)
  end

  private

  def sponsor_stamp_counts
    @sponsor_stamp_counts ||= event.sponsor_visits.group(:sponsor_key).count
  end
end
