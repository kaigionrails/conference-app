class AddTrackToTalks < ActiveRecord::Migration[7.0]
  def change
    add_column :talks, :track, :string, null: false
  end
end
