# @rbs module-self ActionController::Base
module SessionsHelper
  class UnauthorizedError < StandardError
  end

  # @rbs @current_user: User

  def omniauth_request_path(provider, return_to:)
    path = "/auth/#{provider}"
    return path if return_to.blank?

    query = {return_to:}.to_query
    "#{path}?#{query}"
  end

  # @rbs return: User
  def current_user!
    raise UnauthorizedError unless session[:user_id]

    # Decorated here rather than left to active_decorator's handling of view
    # assigns: the header reaches the profile through this helper, and whether
    # @current_user was set before rendering would otherwise decide whether
    # ProfileDecorator#icon_image exists.
    @current_user ||= ActiveDecorator::Decorator.instance.decorate(User.find(session[:user_id]))
  end

  # @rbs return: User?
  def current_user
    current_user!
  rescue UnauthorizedError
    nil
  end

  # @rbs return: Symbol
  def current_locale
    I18n.locale
  end

  # @rbs return: bool
  def logged_in?
    current_user!.present?
  rescue UnauthorizedError
    false
  end
end
