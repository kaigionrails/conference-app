class Admin::LiveStreamArchivesController < AdminController
  # @rbs @before: ActiveSupport::TimeWithZone?
  # @rbs @videos: Array[CloudflareStreamVideo]
  # @rbs @older_before: ActiveSupport::TimeWithZone?
  # @rbs @live_streams: Hash[String, CloudflareStreamLiveStream]
  # @rbs @video: CloudflareStreamVideo
  # @rbs @live_stream: CloudflareStreamLiveStream?

  # Lists the recordings on Cloudflare Stream, including those whose live input is gone from it or from the app.
  # @rbs return: void
  def index
    @before = parse_before(params[:before])
    videos = begin
      CloudflareStreamVideo.ready_videos(before: @before)
    rescue Faraday::Error => e
      Rails.logger.warn("Admin::LiveStreamArchivesController: #{e.class} on listing before=#{@before&.utc&.iso8601(6).inspect}")
      nil
    end
    if videos.nil?
      flash.now[:alert] = "Failed to list the archives from Cloudflare"
      videos = [] #: Array[CloudflareStreamVideo]
    end
    page = videos.first(CloudflareStreamVideo::PER_PAGE)
    # The 51st video only tells that older ones exist.
    @older_before = page.last&.created_at if videos.size > CloudflareStreamVideo::PER_PAGE
    # Uploaded videos, which have no live input, are not archives.
    @videos = page.select(&:archive?)
    @live_streams = CloudflareStreamLiveStream.includes(:event).where(uid: @videos.map(&:live_input_uid)).index_by(&:uid)
  end

  # The URL of this page is the link to share the archive.
  # @rbs return: void
  def show
    video = CloudflareStreamVideo.find(params[:id])
    raise ActiveRecord::RecordNotFound, "Live stream archive not found: #{params[:id]}" unless video&.archive?

    @video = video
    @live_stream = CloudflareStreamLiveStream.includes(:event).find_by(uid: video.live_input_uid)
  rescue Faraday::Error => e
    Rails.logger.warn("Admin::LiveStreamArchivesController: #{e.class} on retrieving uid=#{params[:id]}")
    flash[:alert] = "Failed to fetch the archive from Cloudflare"
    redirect_to admin_live_stream_archives_path
  end

  # A value that is not ISO 8601, such as one rewritten by hand, falls back to the newest page.
  # @rbs value: untyped
  # @rbs return: ActiveSupport::TimeWithZone?
  private def parse_before(value)
    Time.zone.iso8601(value) if value.is_a?(String) && value.present?
  rescue ArgumentError
    nil
  end
end
