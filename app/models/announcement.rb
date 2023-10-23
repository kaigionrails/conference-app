class Announcement < ApplicationRecord
  belongs_to :event
  has_rich_text :content

  enum :status, draft: "draft", published: "published"

  validate :cannot_change_to_draft_if_published
  before_save ->(ann){ ann.published_at ||= Time.current if ann.status_change == ["draft", "published"] }

  def cannot_change_to_draft_if_published
    if status_change == ["published", "draft"]
      errors.add(:status, "Published announce cannot change to draft")
    end
  end
end
