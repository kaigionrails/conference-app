class Admin::LiveStreamBulkUpdatesController < AdminController
  # Updates every live stream on the Live page from the Cloudflare API.
  # Unlike the update of each live stream, a failure keeps the live stream,
  # so that an outage or an expired token of the API does not remove them all.
  # @rbs return: void
  def create
    failed = CloudflareStreamLiveStream.order(:id).reject do |live_stream|
      live_stream.update_stream(destroy_when_gone: false)
    rescue Faraday::Error
      false
    end

    if failed.empty?
      flash[:success] = "Updated all live streams"
    else
      flash[:alert] = "Failed to update: #{failed.map(&:name).join(", ")}"
    end
    redirect_to admin_live_streams_path
  end
end
