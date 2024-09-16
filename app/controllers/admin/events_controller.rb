class Admin::EventsController < AdminController
  def index
    @events = Event.all
    @ongoing_event = OngoingEvent.first
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def edit
    @event = Event.find(params[:id])
    @ongoing_event = OngoingEvent.first
  end

  def create
    param = event_params.to_h.dup
    start_date = param.delete(:start_date_jst)
    end_date = param.delete(:end_date_jst)
    start_date_with_zone = Time.zone.parse("#{start_date} +0900") if start_date.present?
    end_date_with_zone = Time.zone.parse("#{end_date} +0900") if end_date.present?
    @event = Event.new(**param, start_date: start_date_with_zone, end_date: end_date_with_zone)
    if @event.save
      flash[:success] = "Create succeeded"
      redirect_to admin_event_path(@event)
    else
      flash[:alert] = "Create failed"
      render :new
    end
  end

  def update
    @event = Event.find(params[:id])
    param = event_params.to_h.dup
    start_date = param.delete(:start_date_jst)
    end_date = param.delete(:end_date_jst)
    start_date_with_zone = Time.zone.parse("#{start_date} +0900") if start_date.present?
    end_date_with_zone = Time.zone.parse("#{end_date} +0900") if end_date.present?
    if @event.update(**param, start_date: start_date_with_zone, end_date: end_date_with_zone)
      flash[:success] = "Update succeeded"
      redirect_to admin_event_path(@event)
    else
      flash[:alert] = "Update failed"
      render :edit
    end
  end

  private def event_params
    params.require(:event).permit(:name, :slug, :start_date_jst, :end_date_jst)
  end
end
