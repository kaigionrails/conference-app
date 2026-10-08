# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20251128180556)
class AddCursorIsJsonFlagToRuns < ActiveRecord::Migration[7.2]
  def change
    add_column(:maintenance_tasks_runs, :cursor_is_json, :boolean, default: false, null: false)
  end
end
