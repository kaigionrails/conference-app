class TalksController < ApplicationController
  def index
    @event = Event.find_by!(slug: params[:event_slug])
    @talks = Talk.eager_load(:speakers).where(event: @event).order(:start_at)
  end

  def show
    event = Event.find_by!(slug: params[:event_slug])
    @talk = Talk.eager_load(:speakers).find_by!(id: params[:id])
  end
end
