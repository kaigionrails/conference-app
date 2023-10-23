class CreateUnreadAnnouncements < ActiveRecord::Migration[7.0]
  def change
    create_table :unread_announcements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true
      t.index [:user_id, :announcement_id], unique: true
      t.timestamps
    end
  end
end
