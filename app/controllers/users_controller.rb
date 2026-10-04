class UsersController < ApplicationController
  include ApplicationHelper

  # @rbs @user: User
  # @rbs @events: Event::ActiveRecord_Relation
  # @rbs @event_friends: untyped
  # @rbs @profile: Profile
  # @rbs @token: String?

  # @rbs return: void
  def show
    @user = User.preload({profile: [:profile_badges, images_attachments: :blob]}).find_by_handle!(params[:username])
    @events = Event.all.order(start_date: :desc)
    @event_friends = @user.profile_exchanges.preload(:event, friend: {profile: {images_attachments: :blob}}).group_by(&:event)
    @profile = @user.profile
    @token = params[:token]

    if logged_in? && @token
      begin
        token = JWT.decode(@token, nil, false)[0] # steep:ignore
        if Time.zone.at(token["exp"]) > Time.current # not expired
          issuer_user = User.find_by_handle!(token["iss"])
          exchange_profile(issuer_user, current_user!) if issuer_user == @user
        else
          flash.now[:alert] = I18n.t("users.show.qr_code_expired")
        end
      rescue JWT::DecodeError
        flash.now[:alert] = I18n.t("users.show.qr_code_read_failed")
      end
    end
  end

  # @rbs user1: User
  # @rbs user2: User
  # @rbs return: void
  private def exchange_profile(user1, user2)
    unless user1 == user2
      # Two people can scan each other's codes at the same moment. Inserting
      # first lets the unique index settle the race, where a find first
      # would let both requests insert.
      ApplicationRecord.transaction do
        ProfileExchange.create_or_find_by!(event: current_event, user: user1, friend: user2)
        ProfileExchange.create_or_find_by!(event: current_event, user: user2, friend: user1)
      end
    end
  end
end
