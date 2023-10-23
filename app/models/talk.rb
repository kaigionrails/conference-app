class Talk < ApplicationRecord
  belongs_to :event
  has_and_belongs_to_many :speakers
  has_many :talk_bookmarks, dependent: :destroy

  def bookmarked_by?(user)
    talk_bookmarks.where(user: user).exists?
  end

  def bookmark_by(user)
    talk_bookmarks.find_by(user: user)
  end
end
