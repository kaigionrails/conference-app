class AssignTitoTicketsController < ApplicationController
  def index
    @event = Event.find_by!(slug: params[:event_slug])
  end

  def create
    event = Event.find_by!(slug: params[:event_slug])
    ticket = TitoTicket.find_by(
      reference: params[:tito_ticket_reference],
      event: event,
      user: nil
    )
    if ticket.nil?
      redirect_to event_live_checkin_path(event.slug), alert: I18n.t("assign_tito_tickets.create.failure")
    elsif current_user.nil?
      session[:ticketholder] = ticket.id
      redirect_to event_live_streams_path(event.slug), notice: I18n.t("assign_tito_tickets.create.success")
    else
      ticket.user = current_user!
      ticket.save!
      redirect_to event_live_streams_path(event.slug), notice: I18n.t("assign_tito_tickets.create.success")
    end
  end
end
