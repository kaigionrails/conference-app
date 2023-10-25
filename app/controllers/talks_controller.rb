class TalksController < ApplicationController
  def index
    @event = Event.find_by!(slug: params[:event_slug])
    @talks = Talk.eager_load(speakers: { avatar_attachment: :blob }).where(event: @event).order(:start_at)
  end

  def show
    @event = Event.find_by!(slug: params[:event_slug])
    @talk = Talk.eager_load(speakers: { avatar_attachment: :blob }).find_by!(id: params[:id])
  end
end
