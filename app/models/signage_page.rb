class SignagePage < ApplicationRecord
  belongs_to :signage_schedule
  has_one_attached :page_image
end
