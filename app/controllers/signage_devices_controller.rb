class SignageDevicesController < ApplicationController
  # @rbs return: void
  def index
    @signage_devices = SignageDevice.all
  end
end
