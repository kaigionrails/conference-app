class SponsorStampsController < ApplicationController
  include ApplicationHelper

  before_action :require_logged_in
  before_action :set_event
  before_action :set_sponsors
  before_action :set_sponsor_from_code, only: [:new, :create]
  before_action :set_visit, only: :show

  def new
    visit = current_user!.sponsor_visits.find_by(event: @event, sponsor_key: @sponsor[:key])
    return redirect_to sponsor_passport_stamp_path(@event.slug, visit) if visit

    @sponsor_logo_url = SponsorCatalog.logo_url(@event.slug, @sponsor)
  end

  def create
    visit = current_user!.sponsor_visits.find_or_create_by!(event: @event, sponsor_key: @sponsor[:key])
    flash[:newly_visited] = visit.previously_new_record?

    redirect_to sponsor_passport_stamp_path(@event.slug, visit), status: :see_other
  end

  def show
    @sponsor = @sponsors.find { |sponsor| sponsor[:key] == @visit.sponsor_key }
    raise ActiveRecord::RecordNotFound unless @sponsor

    @newly_visited = flash[:newly_visited] == true
    flash.delete(:newly_visited)

    @passport = SponsorPassport.new(event: @event, user: current_user!)
    @visit_number = @passport.stamp_number_for(@sponsor[:key])
    @progress = @passport.progress
  end

  private

  def set_event
    @event = current_event
    raise ActiveRecord::RecordNotFound unless @event&.slug == params[:sponsor_passport_event_slug]
  end

  def set_sponsors
    @sponsors = SponsorCatalog.with_booth(@event.slug)
  end

  def set_sponsor_from_code
    @sponsor = SponsorVisitToken.find_sponsor(event_slug: @event.slug, sponsors: @sponsors, token: params[:code])
    raise ActiveRecord::RecordNotFound unless @sponsor
  end

  def set_visit
    @visit = current_user!.sponsor_visits.find_by!(id: params[:id], event: @event)
  end
end
