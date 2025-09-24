class SubscreenController < ApplicationController
  layout "subscreen"

  def index
    @shirataki_url = Rails.configuration.x.shirataki.url
  end
end
