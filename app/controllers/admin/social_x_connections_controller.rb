class Admin::SocialXConnectionsController < AdminController
  # 接続開始。PKCE の code_verifier と CSRF 用 state を session に置いて X へ送る
  # @rbs return: void
  def create
    authorization = Social::XOauth.build_authorization
    session[:social_x_oauth] = {"state" => authorization.state, "code_verifier" => authorization.code_verifier}
    redirect_to authorization.url, allow_other_host: true
  end

  # @rbs return: void
  def callback
    pending = session.delete(:social_x_oauth)
    if params[:error].present?
      return fail_with("X authorization denied: #{params[:error]}")
    end
    if pending.blank? || params[:state].blank? || !ActiveSupport::SecurityUtils.secure_compare(pending["state"].to_s, params[:state].to_s)
      return fail_with("state mismatch")
    end
    if params[:code].blank?
      return fail_with("code is missing")
    end

    token = Social::XOauth.exchange_code!(code: params[:code], code_verifier: pending["code_verifier"])
    me = Social::XOauth.me!(access_token: token.fetch("access_token"))
    expected = Rails.configuration.x.social.x_screen_name.to_s
    if expected.blank? || me.fetch("username").casecmp?(expected) == false
      return fail_with("connected account @#{me["username"]} does not match SOCIAL_X_SCREEN_NAME (@#{expected})")
    end

    record = SocialOauthToken.find_or_initialize_by(platform: "x")
    # 再接続なら、上書きで DB から消える旧 refresh token を X 側でも失効させる (best-effort)
    revoke_warning = record.persisted? ? revoke_best_effort(record) : nil
    record.update!(
      access_token: token.fetch("access_token"),
      refresh_token: token.fetch("refresh_token"),
      access_token_expires_at: token.fetch("expires_in").to_i.seconds.from_now,
      screen_name: me.fetch("username"),
      remote_user_id: me.fetch("id"),
      scopes: token["scope"].presence || SocialOauthToken::X_SCOPES.join(" "),
      connected_by: current_user!,
      connected_at: Time.current
    )
    flash[:success] = "Connected as @#{record.screen_name}"
    flash[:alert] = revoke_warning if revoke_warning
    redirect_to admin_social_announcements_path
  rescue Social::PostError => e
    fail_with(e.message)
  end

  # @rbs return: void
  def destroy
    token = SocialOauthToken.find_by(platform: "x")
    revoke_warning = token && revoke_best_effort(token)
    token&.destroy!
    flash[:success] = "X disconnected"
    flash[:alert] = revoke_warning if revoke_warning
    redirect_to admin_social_announcements_path
  end

  # X 側の revoke に失敗しても DB の削除・上書きは続行し、手動で外すよう促す
  # @rbs token: SocialOauthToken
  # @rbs return: String? -- 失敗時の警告文
  private def revoke_best_effort(token)
    token.revoke_remote!
    nil
  rescue Social::PostError => e
    "Revoking the previous token at X failed (#{e.message}). Remove the app from https://x.com/settings/connected_apps manually."
  end

  # @rbs message: String
  # @rbs return: void
  private def fail_with(message)
    flash[:alert] = "X connection failed: #{message}"
    redirect_to admin_social_announcements_path
  end
end
