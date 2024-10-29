class ApplicationRecord < ActiveRecord::Base
  # @rbs @current_event: Event?

  primary_abstract_class

  def current_event
    @current_event ||= (OngoingEvent.exists? ? OngoingEvent.first.event : Event.find_by(slug: Event::ONGOING_EVENT_SLUG))
  end
end
