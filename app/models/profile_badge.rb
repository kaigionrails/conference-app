class ProfileBadge < ApplicationRecord
  COLOR_CODE_REGEXP = %r[\A#\h{6}\z] # Color code e.g. #00FF22, #1234ab
  has_many :profile_badges_profiles, dependent: :destroy
  has_many :profiles, through: :profile_badges_profiles

  validates :background_color_code, format: {with: COLOR_CODE_REGEXP}
  validates :border_color_code, format: {with: COLOR_CODE_REGEXP}
  validates :text, uniqueness: true
end
