class CreateProfileBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :profile_badges do |t|
      t.string :text, null: false
      t.string :border_color_code, null: false
      t.string :background_color_code, null: false
      t.boolean :restricted, null: false, default: false
      t.timestamps
    end

    create_join_table(:profile_badges, :profiles) do |t|
      t.index :profile_id
    end
  end
end
