module EventHelper
  def prepare_current_event
    allow_any_instance_of(ApplicationHelper).to receive(:current_event).and_return(prepare_event)
  end

  private def prepare_event
    event = Event.find_or_initialize_by(slug: Event::ONGOING_EVENT_SLUG)

    unless event.persisted?
      event.name = "Kaigi on Rails 2023"
      event.start_date = Time.zone.parse("2023-10-27 00:00:00 +0900")
      event.end_date = Time.zone.parse("2023-10-28 23:59:59 +0900")
      event.save
      event
    end

    event
  end
end
