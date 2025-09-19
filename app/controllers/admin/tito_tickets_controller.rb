class Admin::TitoTicketsController < AdminController
  def index
    @events = Event.all
    @event = @events.find_by(slug: params[:event])
    @tito_tickets = TitoTicket.eager_load(:event, :user).then { |relation|
      @event ? relation.where(event: @event) : relation
    }.page(params[:page]).per(100)
  end

  def show
    @tito_ticket = TitoTicket.eager_load(:event, :user).find(params[:id])
  end
end
