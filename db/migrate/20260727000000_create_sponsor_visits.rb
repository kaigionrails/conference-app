class CreateSponsorVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsor_visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string :sponsor_key, null: false

      t.timestamps
    end

    add_index :sponsor_visits, [:user_id, :event_id, :sponsor_key], unique: true
  end
end
