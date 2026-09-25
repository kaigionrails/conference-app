class ApplicationController < ActionController::Base
  # @rbs! include _RbsRailsPathHelpers

  include SessionsHelper
  include Authenticatable

  before_action :set_variant!

  around_action :switch_locale

  def require_logged_in
    return if logged_in?

    redirect_to login_path(return_to: request.get? ? request.fullpath : nil)
  end

  # @rbs { () -> untyped } -> untyped
  def switch_locale(&action)
    locale = requested_locale || current_user&.locale_setting&.preferred_locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # Carries ?locale through every generated URL. A visitor who is not logged in
  # has nowhere else to keep it -- LocaleSetting needs a user -- so without
  # this it survives a single page view and the next link or redirect drops
  # back to the default.
  #
  # @rbs return: Hash[Symbol, String]
  def default_url_options
    locale = requested_locale
    locale ? {locale: locale} : {}
  end

  # @rbs return: String?
  private def requested_locale
    locale = params[:locale]
    locale if locale.present? && I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end

  private def set_variant!
    if Woothee.parse(request.user_agent)[:category] == :smartphone
      request.variant = :mobile
    end
  end
end
