class SignageDevicesController < ApplicationController
  def index
    @signage_devices = SignageDevice.all
  end
end
