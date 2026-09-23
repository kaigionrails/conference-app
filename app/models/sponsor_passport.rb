class SponsorPassport
  attr_reader :event

  def initialize(event:, user:)
    @event = event
    @user = user
  end

  def sponsors
    @sponsors ||= SponsorCatalog.with_booth(event.slug)
  end

  def visited?(sponsor_key)
    stamp_numbers.key?(sponsor_key)
  end

  def stamp_number_for(sponsor_key)
    stamp_numbers.fetch(sponsor_key)
  end

  def progress
    @progress ||= SponsorVisitProgress.new(
      visited_count: stamp_numbers.size,
      total_count: sponsors.size
    )
  end

  def community_stamp_count
    @community_stamp_count ||= SponsorVisit.where(event:, sponsor_key: sponsors.pluck(:key)).count
  end

  def next_sponsors
    unvisited_sponsors = sponsors.reject { |sponsor| visited?(sponsor[:key]) }
    return [] if unvisited_sponsors.empty?

    unvisited_sponsors.rotate(progress.visited_count % unvisited_sponsors.size).first(2)
  end

  private

  attr_reader :user

  def stamp_numbers
    @stamp_numbers ||= user.sponsor_visits
      .where(event:, sponsor_key: sponsors.pluck(:key))
      .order(:created_at, :id)
      .pluck(:sponsor_key)
      .each_with_index
      .to_h { |sponsor_key, index| [sponsor_key, index + 1] }
  end
end
