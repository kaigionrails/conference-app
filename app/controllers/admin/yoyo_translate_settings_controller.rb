class Admin::YoyoTranslateSettingsController < AdminController
  # @rbs @yoyo_translate_setting: YoyoTranslateSetting
  # @rbs @cloudflare_stream_live_streams: CloudflareStreamLiveStream::ActiveRecord_Relation

  # Creates the setting of the ongoing event on the first save and updates it afterwards.
  # A failure re-renders the Live page, which keeps the input and shows the errors on the form.
  # @rbs return: void
  def update
    @yoyo_translate_setting = YoyoTranslateSetting.find_or_initialize_by(event: OngoingEvent.first!.event)
    if @yoyo_translate_setting.update(yoyo_translate_setting_params)
      redirect_to admin_live_streams_path
    else
      @cloudflare_stream_live_streams = CloudflareStreamLiveStream.order(:id)
      render "admin/live_streams/index", status: :unprocessable_content
    end
  end

  private def yoyo_translate_setting_params
    params.require(:yoyo_translate_setting).permit(:magenta_hall_url, :lime_hall_url)
  end
end
