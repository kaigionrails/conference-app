class CreateWebpushSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :webpush_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :auth_key, null: false
      t.string :p256dh_key, null: false
      t.timestamps
    end
  end
end
