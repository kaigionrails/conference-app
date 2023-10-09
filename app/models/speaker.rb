class Speaker < ApplicationRecord
  has_and_belongs_to_many :talks
end
