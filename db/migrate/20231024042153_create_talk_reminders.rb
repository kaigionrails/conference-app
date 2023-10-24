class CreateTalkReminders < ActiveRecord::Migration[7.0]
  def change
    create_table :talk_reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :talk, null: false, foreign_key: true
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at, null: true
      t.timestamps
    end
  end
end
