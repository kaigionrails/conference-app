class AddTitleToAnnouncements < ActiveRecord::Migration[7.0]
  def change
    add_column :announcements, :title, :string, null: false
  end
end
