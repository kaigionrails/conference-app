class CreateProfileExchanges < ActiveRecord::Migration[7.0]
  def change
    create_table :profile_exchanges do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :friend, null: false, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end
  end
end
