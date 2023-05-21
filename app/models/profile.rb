class Profile < ApplicationRecord
  belongs_to :user
  has_many_attached :images
end
