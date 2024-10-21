class CreateCloudflareStreamLiveStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :cloudflare_stream_live_streams do |t|
      t.references :event, null: false, foreign_key: true
      t.string :uid, null: false
      t.string :name, null: false
      t.jsonb :stream_raw_response
      t.jsonb :stream_videos_raw_response

      t.timestamps
    end
  end
end
