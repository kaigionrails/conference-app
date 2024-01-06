class HomeController < ApplicationController
  def index
    redirect_to about_path unless logged_in?
    nil
  end
end
