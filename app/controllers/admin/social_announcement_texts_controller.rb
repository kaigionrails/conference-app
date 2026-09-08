class Admin::SocialAnnouncementTextsController < AdminController
  # 各言語カラムは Turbo Frame。成功時は自カラムの差し替えと保存トーストを Turbo Stream で返すので、
  # もう片方のカラムで入力中の内容は消えない。失敗時はエラー付きのカラムを 422 で返す。

  # @rbs return: void
  def create
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    text = announcement.texts.build(locale: text_params[:locale], body: text_params[:body])
    if text.save
      render_saved announcement, text
    else
      render_column announcement, text
    end
  end

  # @rbs return: void
  def update
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    text = announcement.texts.find(params[:id])
    if text.update(body: text_params[:body])
      render_saved announcement, text
    else
      render_column announcement, text
    end
  end

  private def text_params
    params.require(:social_announcement_text).permit(:locale, :body)
  end

  # @rbs announcement: SocialAnnouncement
  # @rbs text: SocialAnnouncementText
  # @rbs return: void
  private def render_saved(announcement, text)
    no_errors = [] #: Array[String]
    respond_to do |format|
      format.html { redirect_to admin_social_announcement_path(announcement) }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("social_announcement_text_#{text.locale}",
            partial: "admin/social_announcements/text_column",
            locals: {announcement: announcement, locale: text.locale, text: text, errors: no_errors}),
          turbo_stream.append("toasts",
            partial: "admin/social_announcements/toast",
            locals: {type: :success, message: "Text (#{text.locale}) saved"})
        ]
      end
    end
  end

  # @rbs announcement: SocialAnnouncement
  # @rbs text: SocialAnnouncementText
  # @rbs return: void
  private def render_column(announcement, text)
    render partial: "admin/social_announcements/text_column",
      locals: {announcement: announcement, locale: text.locale, text: text, errors: text.errors.full_messages},
      status: :unprocessable_content
  end
end
