class AddUniqueIndexToUsersName < ActiveRecord::Migration[8.1]
  def change
    add_index :users, "lower(name)", unique: true, name: "index_users_on_lower_name"
  end
end
