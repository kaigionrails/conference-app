class LiveStreamsController < ApplicationController
  before_action :require_ticket

  # @rbs @live_stream: CloudflareStreamLiveStream

  # @rbs return: void
  def index
    @event = Event.find_by!(slug: params[:event_slug])
    live_streams = CloudflareStreamLiveStream.where(event: @event)
    @backstage = current_user&.organizer? || current_user&.operator?
    # FIXME: too hardcoded...
    @live_streams = {
      day1: {
        red_ja: live_streams.detect { |s| s.name.include?("day1-red-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        blue_ja: live_streams.detect { |s| s.name.include?("day1-blue-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
      },
      day2: {
        red_ja: live_streams.detect { |s| s.name.include?("day2-red-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        red_raw: live_streams.detect { |s| s.name.include?("day2-red-raw") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        blue_ja: live_streams.detect { |s| s.name.include?("day2-blue-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
      },
      test: live_streams.detect { |s| s.name.include?("test") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
    }
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
          || current_user!.organizer? \
          || current_user!.operator?
        )
      true
    elsif session[:ticketholder] && TitoTicket.where(id: session[:ticketholder].to_i).exists?
      # user has ticket. do nothing
      true
    else
      redirect_to event_live_checkin_path(params[:event_slug])
    end
  end
end
