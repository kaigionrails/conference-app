class TalksController < ApplicationController
  def index
    event = Event.find_by!(slug: params[:event_slug])
    @talks = Talk.eager_load(:speakers).where(event: event).order(:start_at)
  end
end
