class CreateAnnouncements < ActiveRecord::Migration[7.0]
  def change
    create_table :announcements do |t|
      t.references :event, null: false, index: true
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.timestamps
    end
  end
end
