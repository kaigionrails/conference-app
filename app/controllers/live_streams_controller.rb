class LiveStreamsController < ApplicationController
  before_action :require_ticket

  # @rbs @live_stream: CloudflareStreamLiveStream

  # @rbs return: void
  def index
    @event = Event.find_by!(slug: params[:event_slug])
  end

  # @rbs return: void
  def show
    # @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end

  private def require_ticket
    true
  end
end
