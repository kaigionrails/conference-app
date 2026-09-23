class SponsorPassportsController < ApplicationController
  include ApplicationHelper

  before_action :require_logged_in

  def show
    event = current_event
    raise ActiveRecord::RecordNotFound unless event&.slug == params[:event_slug]

    @passport = SponsorPassport.new(event:, user: current_user!)
  end
end
