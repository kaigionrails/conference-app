class CreateTalkBookmarks < ActiveRecord::Migration[7.0]
  def change
    create_table :talk_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :talk, null: false, foreign_key: true
      t.index [:user_id, :talk_id], unique: true
      t.timestamps
    end
  end
end
