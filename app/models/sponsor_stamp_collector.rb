class SponsorStampCollector
  Result = Data.define(:visit, :newly_visited, :newly_completed)

  def initialize(user:, event:)
    @user = user
    @event = event
  end

  def collect!(sponsor_key:)
    keys = SponsorCatalog.with_booth(@event.slug).pluck(:key)
    raise ActiveRecord::RecordNotFound unless keys.include?(sponsor_key)

    @user.with_lock do
      visit = @user.sponsor_visits.find_or_create_by!(event: @event, sponsor_key:)
      newly_visited = visit.previously_new_record?
      completion = SponsorStampRallyCompletion.award_if_eligible!(user: @user, event: @event)
      Result.new(visit:, newly_visited:, newly_completed: completion&.previously_new_record? == true)
    end
  end
end
