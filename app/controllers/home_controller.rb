class HomeController < ApplicationController
  # @rbs return: void
  def index
    redirect_to about_path unless logged_in?
    nil
  end
end
