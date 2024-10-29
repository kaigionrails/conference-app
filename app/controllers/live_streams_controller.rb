class LiveStreamsController < ApplicationController
  # @rbs return: void
  def show
    @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end
end
