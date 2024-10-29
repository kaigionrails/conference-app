class ApplicationController < ActionController::Base
  # @rbs! include _RbsRailsPathHelpers

  include SessionsHelper

  before_action :set_variant!

  def require_logged_in
    redirect_to login_path unless logged_in?
  end

  private def set_variant!
    if Woothee.parse(request.user_agent)[:category] == :smartphone
      request.variant = :mobile
    end
  end
end
