class SocialOauthToken < ApplicationRecord
  PLATFORMS = %w[x].freeze
  X_SCOPES = %w[tweet.read tweet.write users.read media.write offline.access].freeze
  REFRESH_SKEW = 5.minutes

  belongs_to :connected_by, class_name: "User"

  encrypts :access_token, :refresh_token

  validates :platform, inclusion: {in: PLATFORMS}
  validates :platform, uniqueness: true
  validates :access_token, :refresh_token, :access_token_expires_at,
    :screen_name, :remote_user_id, :scopes, :connected_at, presence: true

  # @rbs return: bool
  def expires_soon?
    access_token_expires_at <= REFRESH_SKEW.from_now
  end

  # X 側で refresh token を失効させる。access token は 2 時間で切れるので refresh だけ落とせばよい。
  # 失敗は PostError のまま上げる (切断自体を止めるかは呼び出し側が決める)
  # @rbs return: void
  def revoke_remote!
    Social::XOauth.revoke!(token: refresh_token, token_type_hint: "refresh_token")
  end

  # refresh token は単回利用。呼び出し側で行ロックを取り、レスポンスの新しい refresh をすぐ書く。
  # @rbs return: void
  def refresh!
    body = Social::XOauth.refresh!(refresh_token: refresh_token)
    update!(
      access_token: body.fetch("access_token"),
      refresh_token: body.fetch("refresh_token"),
      access_token_expires_at: body.fetch("expires_in").to_i.seconds.from_now,
      scopes: body["scope"].presence || scopes
    )
  end
end
