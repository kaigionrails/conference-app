class Admin::SocialAnnouncementMediaController < AdminController
  # @rbs return: void
  def create
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    medium = announcement.media.build(
      file: media_params[:file],
      position: announcement.media.maximum(:position).to_i + 1
    )
    if medium.save
      flash[:success] = "Media attached"
    else
      flash[:alert] = medium.errors.full_messages.join(", ")
    end
    redirect_to admin_social_announcement_path(announcement)
  end

  # alt text と並び順の更新。カードは Turbo Frame で、成功時のリダイレクトは自カードだけ
  # 差し替えるため、他の入力欄の内容は消えない。失敗時はエラー付きカードを 422 で返す
  # @rbs return: void
  def update
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    medium = announcement.media.find(params[:id])
    if medium.update(**media_params.slice(:alt_text_ja, :alt_text_en, :position))
      redirect_to admin_social_announcement_path(announcement)
    else
      render partial: "admin/social_announcements/media_card",
        locals: {announcement: announcement, medium: medium, published: announcement.published_at.present?, errors: medium.errors.full_messages},
        status: :unprocessable_content
    end
  end

  # @rbs return: void
  def destroy
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    medium = announcement.media.find(params[:id])
    medium.destroy!
    flash[:success] = "Media removed"
    redirect_to admin_social_announcement_path(announcement)
  end

  private def media_params
    params.require(:social_announcement_media).permit(:file, :alt_text_ja, :alt_text_en, :position)
  end
end
