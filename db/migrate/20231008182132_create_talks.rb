class CreateTalks < ActiveRecord::Migration[7.0]
  def change
    create_table :talks do |t|
      t.references :event, null: false
      t.string :title, null: false
      t.text :abstract, null: false, default: ""
      t.datetime :start_at, null: false
      t.integer :duration_minutes, null: false
      t.timestamps
    end
  end
end
