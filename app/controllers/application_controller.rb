class ApplicationController < ActionController::Base
  include SessionsHelper

  def require_logged_in
    redirect_to login_path unless logged_in?
  end
end
