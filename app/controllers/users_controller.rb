class UsersController < ApplicationController
  include ApplicationHelper

  # @rbs @user: User
  # @rbs @events: Event::ActiveRecord_Relation
  # @rbs @event_friends: untyped
  # @rbs @profile: Profile
  # @rbs @token: String?
  # @rbs @newly_exchanged: bool
  # @rbs @community_profile_exchange_count: Integer?

  # @rbs return: void
  def show
    @user = User.preload({profile: [:profile_badges, images_attachments: :blob]}).find_by_handle!(params[:username])
    @profile = @user.profile
    @token = params[:token]
    @newly_exchanged = false

    if logged_in? && @token
      begin
        token = JWT.decode(@token, nil, false)[0] # steep:ignore
        if Time.zone.at(token["exp"]) > Time.current # not expired
          issuer_user = User.find_by_handle!(token["iss"])
          @newly_exchanged = exchange_profile(issuer_user, current_user!) if issuer_user == @user
        else
          flash.now[:alert] = I18n.t("users.show.qr_code_expired")
        end
      rescue JWT::DecodeError
        flash.now[:alert] = I18n.t("users.show.qr_code_read_failed")
      end
    end

    # Loaded after the exchange above, so the page shows the person who
    # has just been met.
    @events = Event.all.order(start_date: :desc)
    @event_friends = @user.profile_exchanges.preload(:event, friend: {profile: {images_attachments: :blob}}).group_by(&:event)
    @community_profile_exchange_count = current_event&.community_profile_exchange_count
  end

  # Returns whether either direction of the exchange was stored just now.
  #
  # @rbs user1: User
  # @rbs user2: User
  # @rbs return: bool
  private def exchange_profile(user1, user2)
    return false if user1 == user2

    # Two people can scan each other's codes at the same moment. Inserting
    # first lets the unique index settle the race, where a find first
    # would let both requests insert.
    ApplicationRecord.transaction do
      exchanges = [
        ProfileExchange.create_or_find_by!(event: current_event, user: user1, friend: user2),
        ProfileExchange.create_or_find_by!(event: current_event, user: user2, friend: user1)
      ]
      exchanges.any?(&:previously_new_record?)
    end
  end
end
