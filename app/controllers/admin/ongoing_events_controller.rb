class Admin::OngoingEventsController < ApplicationController
  # @rbs return: void
  def update
    @ongoing_event = OngoingEvent.first
    if @ongoing_event.update(ongoing_event_params)
      flash[:success] = "Update succeeded"
    else
      flash[:alert] = "Update failed"
    end
    redirect_to admin_event_path(@ongoing_event.event_id)
  end

  # @rbs return: void
  def create
    @ongoing_event = OngoingEvent.new(ongoing_event_params)
    if @ongoing_event.save
      flash[:success] = "Update succeeded"
    else
      flash[:alert] = "Update failed"
    end
    redirect_to admin_event_path(@ongoing_event.event_id)
  end

  private def ongoing_event_params
    params.require(:ongoing_event).permit(:event_id)
  end
end
