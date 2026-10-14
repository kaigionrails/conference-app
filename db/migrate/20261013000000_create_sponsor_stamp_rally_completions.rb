class CreateSponsorStampRallyCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsor_stamp_rally_completions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :event, null: false, foreign_key: true
      t.datetime :completed_at, null: false
      t.timestamps
    end

    add_index :sponsor_stamp_rally_completions, [:user_id, :event_id], unique: true
  end
end
