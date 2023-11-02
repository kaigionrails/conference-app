module SessionsHelper
  class UnauthorizedError < StandardError
  end

  def current_user!
    raise UnauthorizedError unless session[:user_id]

    @current_user ||= User.find(session[:user_id])
  end

  def logged_in?
    current_user!.present?
  rescue UnauthorizedError
    false
  end
end
