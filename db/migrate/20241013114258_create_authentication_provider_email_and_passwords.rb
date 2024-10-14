class CreateAuthenticationProviderEmailAndPasswords < ActiveRecord::Migration[8.0]
  def change
    create_table :authentication_provider_email_and_passwords do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false, index: {unique: true}
      t.string :password_digest, null: false

      t.timestamps
    end
  end
end
