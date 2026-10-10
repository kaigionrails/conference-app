class Speaker < ApplicationRecord
  has_many :speakers_talks, dependent: :delete_all
  has_many :talks, through: :speakers_talks

  has_one_attached :avatar do |attachable|
    # Talk list (80px) and talk page (up to 96px), at twice the larger.
    attachable.variant :thumb, resize_to_limit: [192, 192], preprocessed: true
  end

  # NOT NULL lets empty strings through, and the talk page links to github.com/#{github_username}.
  validates :name, presence: true
  validates :github_username, presence: true
end
