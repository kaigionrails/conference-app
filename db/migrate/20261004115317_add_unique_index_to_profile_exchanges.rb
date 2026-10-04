class AddUniqueIndexToProfileExchanges < ActiveRecord::Migration[8.1]
  def change
    add_index :profile_exchanges, [:event_id, :user_id, :friend_id], unique: true
    # The new index leads with event_id, so it serves lookups by event alone.
    remove_index :profile_exchanges, :event_id
  end
end
