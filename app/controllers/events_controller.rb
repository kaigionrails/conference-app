class EventsController < ApplicationController
  def show
    @event = Event.find_by!(slug: params[:event_slug])
  end
end
