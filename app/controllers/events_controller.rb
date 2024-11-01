class EventsController < ApplicationController
  # @rbs @event: Event

  # @rbs return: void
  def show
    @event = Event.find_by!(slug: params[:event_slug])
  end
end
