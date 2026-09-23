class CreateAuthenticationProviderGoogles < ActiveRecord::Migration[8.1]
  def change
    create_table :authentication_provider_googles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uid, null: false

      t.timestamps
    end
    add_index :authentication_provider_googles, :uid, unique: true
  end
end
