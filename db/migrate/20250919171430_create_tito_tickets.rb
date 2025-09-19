class CreateTitoTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tito_tickets do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: true
      t.bigint :tito_id, null: false
      t.string :slug, null: false
      t.string :reference, null: false
      t.string :unique_url, null: false
      t.string :state, null: false

      t.timestamps
    end
    add_index :tito_tickets, :tito_id
    add_index :tito_tickets, :reference
  end
end
