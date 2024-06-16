class AddUniqueIndexToProfileBadge < ActiveRecord::Migration[7.0]
  def change
    add_index :profile_badges, :text, unique: true
  end
end
