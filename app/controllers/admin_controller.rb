class AdminController < ApplicationController
  before_action :require_organizer
  layout "admin"

  # @rbs return: void
  def index
  end

  private def require_organizer
    if logged_in? && current_user!.organizer?
      # pass
    else
      flash[:alert] = "Require organizer role"
      redirect_to root_path
    end
  end
end
