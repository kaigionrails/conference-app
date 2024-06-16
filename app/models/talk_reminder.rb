class TalkReminder < ApplicationRecord
  belongs_to :user
  belongs_to :talk

  validates :scheduled_at, presence: true
end
