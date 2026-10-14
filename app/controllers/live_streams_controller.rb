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
    # A live input for #test never comes up in the tabs of the halls.
    streams_of_halls = live_streams.reject(&:test?)
    @live_streams = {
      magenta_ja: streams_of_halls.detect { |s| s.hall == "magenta" && s.lang == "ja" }&.url || "",
      magenta_en: streams_of_halls.detect { |s| s.hall == "magenta" && s.lang == "en" }&.url || "",
      lime_ja: streams_of_halls.detect { |s| s.hall == "lime" && s.lang == "ja" }&.url || "",
      lime_en: streams_of_halls.detect { |s| s.hall == "lime" && s.lang == "en" }&.url || "",
      test: live_streams.detect(&:test?)&.url || ""
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
