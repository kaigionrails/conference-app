class LiveStreamsController < ApplicationController
  before_action :require_ticket

  # @rbs @live_stream: CloudflareStreamLiveStream
  # @rbs @yoyo_translate_setting: YoyoTranslateSetting?

  # @rbs return: void
  def index
    @event = Event.find_by!(slug: params[:event_slug])

    # TODO: policy management...
    if Time.zone.now >= @event.end_date && !current_user&.organizer?
      flash[:alert] = I18n.t("live_streams.index.event_ended", event_name: @event.name)
      redirect_to root_path
      return
    end

    live_streams = CloudflareStreamLiveStream.where(event: @event)
    @backstage = if current_user&.organizer? || current_user&.operator?
      "true"
    else
      "false"
    end
    # FIXME: too hardcoded...
    @live_streams = {
      day1: {
        magenta_ja: live_streams.detect { |s| s.name.include?("day1-magenta-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        lime_ja: live_streams.detect { |s| s.name.include?("day1-lime-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
      },
      day2: {
        magenta_ja: live_streams.detect { |s| s.name.include?("day2-magenta-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        magenta_raw: live_streams.detect { |s| s.name.include?("day2-magenta-raw") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || "",
        lime_ja: live_streams.detect { |s| s.name.include?("day2-lime-ja") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
      },
      test: live_streams.detect { |s| s.name.include?("test") }&.stream_videos_raw_response&.dig("result", 0, "playback", "hls") || ""
    }
    @yoyo_translate_setting = @event.yoyo_translate_setting
  end

  # @rbs return: void
  def show
    # @live_stream = CloudflareStreamLiveStream.find(params[:id])
  end

  private def require_ticket
    event = Event.find_by(slug: params[:event_slug])

    # logged_in, has current event ticket or organizer
    if current_user &&
        (
          current_user!.tito_tickets.where(event: event, state: "complete").exists? ||
          current_user!.organizer? ||
          current_user!.operator?
        )
      true
    elsif session[:ticketholder] &&
        # Same conditions as the branch above. Checking only that the id exists
        # let a ticket for another event, or one that never completed, through.
        TitoTicket.where(id: session[:ticketholder].to_i, event: event, state: "complete").exists?
      true
    else
      redirect_to event_live_checkin_path(params[:event_slug])
    end
  end
end
