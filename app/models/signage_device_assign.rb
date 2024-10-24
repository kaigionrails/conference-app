class SignageDeviceAssign < ApplicationRecord
  belongs_to :signage_panel
  belongs_to :signage_device
end
