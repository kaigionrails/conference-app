class HomeController < ApplicationController
  def index
    redirect_to about_path unless logged_in?
    return
  end
end
