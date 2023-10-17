class PwaController < ApplicationController
  protect_from_forgery except: :service_worker
  layout false

  def service_worker
    response.headers['Cache-Control'] = "no-cache"
  end

  def manifest
    response.headers['Cache-Control'] = "no-cache"
  end
end
