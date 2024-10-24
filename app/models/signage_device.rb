class SignageDevice < ApplicationRecord
  has_many :signage_device_assigns, dependent: :destroy

  def signage_panel
    signage_device_assigns.first&.signage_panel # device側から見えるpanelは高々1つ
  end
end
