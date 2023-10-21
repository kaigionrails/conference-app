class Announcement < ApplicationRecord
  belongs_to :event
  has_rich_text :content

  enum :status, draft: "draft", published: "published"
end
