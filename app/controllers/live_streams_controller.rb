class LiveStreamsController < ApplicationController
  # before_action :require_ticket

  # @rbs @live_stream: CloudflareStreamLiveStream

  # @rbs return: void
  def index
    @event = Event.find_by!(slug: params[:event_slug])
    # @live_streams = CloudflareStreamLiveStream.where(event: @event)
  end

  # @rbs return: void
  def show
    # @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end

  private def require_ticket
    # logged_in, has current event ticket or organizer
    if current_user &&
        (
          current_user!.tito_tickets.where(event: Event.find_by(slug: params[:event_slug]), state: "complete").exists? \
          || current_user!.organizer?
        )
      true
    else
      redirect_to root_path
    end
  end
end
