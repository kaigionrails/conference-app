class OperatorsController < ApplicationController
  before_action :require_logged_in
  before_action :require_operator

  # @rbs return: void
  def index
  end

  private def require_operator
    if !(current_user!.operator? || current_user!.organizer?)
      flash[:alert] = "You have no permission"
      redirect_to about_path
    end
  end
end
