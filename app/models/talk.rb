class Talk < ApplicationRecord
  belongs_to :event
  has_many :speakers_talks, dependent: :destroy
  has_many :speakers, through: :speakers_talks
  has_many :talk_bookmarks, dependent: :destroy
  has_many :talk_reminders, dependent: :destroy

  def bookmarked_by?(user)
    talk_bookmarks.where(user: user).exists?
  end

  def bookmark_by(user)
    talk_bookmarks.find_by(user: user)
  end
end
