class CreateSignages < ActiveRecord::Migration[8.0]
  def change
    create_table :signages do |t|
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end

    create_table :signage_schedules do |t|
      t.references :signage, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.timestamps
    end

    create_table :signage_panels do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :signage_schedule_assigns do |t| # standard:disable Rails/CreateTableWithTimestamps
      t.references :signage_schedule, null: false, index: true
      t.references :signage_panel, null: false, index: true
    end

    create_table :signage_pages do |t|
      t.references :signage_schedule, null: false, foreign_key: true
      t.integer :order, null: false
      t.integer :duration_second, null: false

      t.timestamps
    end

    create_table :signage_devices do |t|
      t.string :device_name, null: false
      t.datetime :last_heaetbeated_at
      t.timestamps
    end

    create_table :signage_device_assigns do |t| # standard:disable Rails/CreateTableWithTimestamps
      t.references :signage_panel, null: false, index: true
      t.references :signage_device, null: false, index: true
    end
  end
end
