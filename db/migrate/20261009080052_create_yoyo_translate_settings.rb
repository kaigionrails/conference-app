class CreateYoyoTranslateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :yoyo_translate_settings do |t|
      t.references :event, null: false, foreign_key: true, index: {unique: true}
      t.string :magenta_hall_url
      t.string :lime_hall_url

      t.timestamps
    end
  end
end
