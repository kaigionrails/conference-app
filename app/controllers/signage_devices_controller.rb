class SignageDevicesController < ApplicationController
  # @rbs @signage_devices: SignageDevice::ActiveRecord_Relation

  # @rbs return: void
  def index
    @signage_devices = SignageDevice.all
  end
end
