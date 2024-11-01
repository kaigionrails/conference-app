class Admin::TalksController < AdminController
  # @rbs @talks: Talk::ActiveRecord_Relation
  # @rbs @talk: Talk

  # @rbs return: void
  def index
    @events = Event.all
    @event = @events.find_by(slug: params[:event])
    @talks = Talk.eager_load(:speakers).order(:start_at).then { |relation|
      @event ? relation.where(event: @event) : relation
    }.page(params[:page]).per(50)
  end

  # @rbs return: void
  def show
    @talk = Talk.eager_load(:speakers).find(params[:id])
  end

  # @rbs return: void
  def edit
    @talk = Talk.find(params[:id])
  end

  # @rbs return: void
  def update
    talk = Talk.find(params[:id])
    update_params = talk_params.dup
    start_at_date = update_params.delete(:start_at_date)
    start_at_time = update_params.delete(:start_at_time)
    start_at_with_zone = Time.zone.parse("#{start_at_date} #{start_at_time} +0900")
    if talk.update(**update_params, start_at: start_at_with_zone)
      flash[:success] = "Update succeeded"
      redirect_to admin_talk_path(talk)
    else
      flash[:alert] = "Update failed"
      redirect_to edit_admin_talk_path(talk)
    end
  end

  private def talk_params
    params.require(:talk).permit(:title, :abstract, :start_at_date, :start_at_time, :track, :duration_minutes)
  end
end
