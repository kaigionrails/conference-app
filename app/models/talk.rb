class Talk < ApplicationRecord
  belongs_to :event
  has_and_belongs_to_many :speakers
  has_many :talk_bookmarks, dependent: :destroy
end
