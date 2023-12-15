class CreateAuthenticationProviderGithubs < ActiveRecord::Migration[7.0]
  def change
    create_table :authentication_provider_githubs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uid, null: false, index: {unique: true}

      t.timestamps
    end
  end
end
