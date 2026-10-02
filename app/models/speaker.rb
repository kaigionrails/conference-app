class Speaker < ApplicationRecord
  has_many :speakers_talks, dependent: :delete_all
  has_many :talks, through: :speakers_talks

  has_one_attached :avatar do |attachable|
    # Talk list (80px) and talk page (up to 96px), at twice the larger.
    attachable.variant :thumb, resize_to_limit: [192, 192], preprocessed: true
  end
end
