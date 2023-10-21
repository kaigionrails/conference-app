class Event < ApplicationRecord
  has_many :talks, dependent: :destroy
  has_many :announcements, dependent: :destroy
end
