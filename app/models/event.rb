class Event < ApplicationRecord
  has_many :talks, dependent: :destroy
end
