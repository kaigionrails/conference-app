class UsersController < ApplicationController
  include ApplicationHelper

  def show
    @user = User.find_by!(name: params[:username])
    @profile = @user.profile
    @token = params[:token]

    if logged_in? && @token
      begin
        token = JWT.decode(@token, nil, false)[0]
        if Time.zone.at(token["exp"]) > Time.current # not expired
          issuer_user = User.find_by!(name: token["iss"])
          exchange_profile(issuer_user, current_user) if issuer_user == @user
        else
          flash.now[:alert] = "QRコードの期限が切れています。もう一度生成したものを読み取ってください。"
        end
      rescue JWT::DecodeError
        flash.now[:alert] = "QRコードの読み取りに失敗しました。もう一度読み取ってください。"
      end
    end
  end

  private def exchange_profile(user1, user2)
    unless user1 == user2
      ApplicationRecord.transaction do
        ProfileExchange.find_or_create_by!(event: current_event, user: user1, friend: user2)
        ProfileExchange.find_or_create_by!(event: current_event, user: user2, friend: user1)
      end
    end
  end
end
