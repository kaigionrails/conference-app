class CreateProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, default: ""
      t.text :description, null: false, default: ""

      t.timestamps
    end
  end
end
