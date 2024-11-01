class LiveStreamsController < ApplicationController
  # @rbs @live_stream: CloudflareStreamLiveStream

  # @rbs return: void
  def show
    @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end
end
