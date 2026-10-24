class Admin::StampRalliesController < AdminController
  def index
    event = if params[:event_id].present?
      Event.find(params[:event_id])
    else
      OngoingEvent.first&.event || Event.order(start_date: :desc, id: :desc).first!
    end

    @events = Event.order(start_date: :desc, id: :desc)
    @stamp_rally = SponsorStampRally.new(event:)
  end
end
