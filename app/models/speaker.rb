class Speaker < ApplicationRecord
  has_many :speakers_talks, dependent: :destroy
  has_many :talks, through: :speakers_talks

  has_one_attached :avatar
end
