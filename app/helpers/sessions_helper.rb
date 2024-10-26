# @rbs module-self ActionController::Base
module SessionsHelper
  class UnauthorizedError < StandardError
  end

  # @rbs @current_user: User

  # @rbs return: User
  def current_user!
    raise UnauthorizedError unless session[:user_id]

    @current_user ||= User.find(session[:user_id])
  end

  # @rbs return: bool
  def logged_in?
    current_user!.present?
  rescue UnauthorizedError
    false
  end
end
