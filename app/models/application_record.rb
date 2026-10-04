class ApplicationRecord < ActiveRecord::Base
  # @rbs @current_event: Event?

  primary_abstract_class

  def current_event
    @current_event ||= OngoingEvent.first&.event
  end
end
