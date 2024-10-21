class LiveStreamsController < ApplicationController
  def show
    @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end
end
