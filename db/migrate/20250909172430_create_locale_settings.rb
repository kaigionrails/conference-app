class CreateLocaleSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :locale_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :preferred_locale, null: false

      t.timestamps
    end
  end
end
