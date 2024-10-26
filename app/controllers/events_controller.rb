class EventsController < ApplicationController
  # @rbs @event: Event

  def show
    @event = Event.find_by!(slug: params[:event_slug])
  end
end
