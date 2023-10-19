class Admin::TalksController < AdminController
  def index
    @talks = Talk.eager_load(:speakers).order(:start_at).page(params[:page]).per(50)
  end
end
