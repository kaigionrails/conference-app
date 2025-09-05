class ApplicationController < ActionController::Base
  # @rbs! include _RbsRailsPathHelpers

  include SessionsHelper

  before_action :set_variant!

  around_action :switch_locale

  def require_logged_in
    redirect_to login_path unless logged_in?
  end

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  private def set_variant!
    if Woothee.parse(request.user_agent)[:category] == :smartphone
      request.variant = :mobile
    end
  end
end
