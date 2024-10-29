class Talk < ApplicationRecord
  belongs_to :event
  has_many :speakers_talks, dependent: :destroy
  has_many :speakers, through: :speakers_talks
  has_many :talk_bookmarks, dependent: :destroy
  has_many :talk_reminders, dependent: :destroy

  # @rbs user: User
  # @rbs return: bool
  def bookmarked_by?(user)
    talk_bookmarks.where(user: user).exists?
  end

  # @rbs user: User
  # @rbs return: TalkBookmark?
  def bookmark_by(user)
    talk_bookmarks.find_by(user: user)
  end
end
