class Admin::SocialAnnouncementTargetPlatformsController < AdminController
  # チェックボックスの状態で TargetPlatform を作成・削除する。
  # 投稿済みプラットフォームの削除はモデル側で中止される。
  # @rbs return: void
  def update
    announcement = SocialAnnouncement.find(params[:social_announcement_id])
    platforms = params.dig(:social_announcement, :platforms) #: untyped
    wanted = platforms.to_a.map { |v| v.to_s } & SocialAnnouncement::PLATFORMS
    errors = [] #: Array[String]

    announcement.target_platforms.each do |target|
      next if wanted.include?(target.platform)

      target.destroy || errors.concat(target.errors.full_messages)
    end
    (wanted - announcement.target_platforms.reload.map(&:platform)).each do |platform|
      target = announcement.target_platforms.create(platform: platform)
      errors.concat(target.errors.full_messages) unless target.persisted?
    end

    if errors.empty?
      flash[:success] = "Target platforms updated"
    else
      flash[:alert] = errors.join(", ")
    end
    redirect_to admin_social_announcement_path(announcement)
  end
end
