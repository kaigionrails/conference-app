class CreateSpeakers < ActiveRecord::Migration[7.0]
  def change
    create_table :speakers do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :github_username, null: false
      t.string :gravatar_hash, null: false
      t.text :bio, null: false, default: ""
      t.timestamps
    end

    create_join_table :speakers, :talks do |t|
      t.index :speaker_id
      t.index :talk_id
    end
  end
end
