class ProfileBadge < ApplicationRecord
  COLOR_CODE_REGEXP = %r[\A#\h{6}\z] # Color code e.g. #00FF22, #1234ab
  has_and_belongs_to_many :profiles

  validates :background_color_code, format: {with: COLOR_CODE_REGEXP}
  validates :border_color_code, format: {with: COLOR_CODE_REGEXP}
  validates :text, uniqueness: true
end
