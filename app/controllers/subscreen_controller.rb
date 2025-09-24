class SubscreenController < ApplicationController
  layout "subscreen"

  def index
    @room = %w(red blue).include?(params[:room]) ? params[:room] : "red"
    @shirataki_url = Rails.configuration.x.shirataki.url
  end
end
