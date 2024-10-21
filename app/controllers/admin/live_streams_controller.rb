class Admin::LiveStreamsController < AdminController
  def index
    @cloudflare_stream_live_streams = CloudflareStreamLiveStream.all
  end

  def new
    @cloudflare_stream_live_stream = CloudflareStreamLiveStream.new
  end

  def create
    if CloudflareStreamLiveStream.create_by_stream_uid(cloudflare_stream_live_stream_params[:uid])
      flash[:success] = "Live stream created successfully"
    else
      flash[:alert] = "Live stream creation failed"
    end
    redirect_to admin_live_streams_path
  end

  def update
    @cloudflare_stream_live_stream = CloudflareStreamLiveStream.find(params[:id])
    if @cloudflare_stream_live_stream.update_stream
      flash[:success] = "Live stream updated successfully"
    else
      flash[:alert] = "Live stream update failed"
    end
    redirect_to admin_live_streams_path
  end

  private def cloudflare_stream_live_stream_params
    params.require(:cloudflare_stream_live_stream).permit(:uid)
  end
end
