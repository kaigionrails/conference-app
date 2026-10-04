class SponsorStampCardsController < ApplicationController
  include ApplicationHelper

  before_action :require_logged_in

  def show
    event = current_event
    raise ActiveRecord::RecordNotFound unless event&.slug == params[:event_slug]

    @stamp_card = SponsorStampCard.new(event:, user: current_user!)
  end
end
