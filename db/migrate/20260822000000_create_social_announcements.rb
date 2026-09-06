class CreateSocialAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :social_announcements do |t|
      t.references :event, null: false, foreign_key: true
      t.string :campaign, null: false
      t.text :note
      t.datetime :published_at
      t.references :created_by, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end

    create_table :social_announcement_texts do |t|
      t.references :social_announcement, null: false, foreign_key: true
      t.string :locale, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :social_announcement_texts, [:social_announcement_id, :locale], unique: true

    create_table :social_announcement_text_reviews do |t|
      t.references :social_announcement_text, null: false, foreign_key: true
      t.references :reviewed_by, null: false, foreign_key: {to_table: :users}
      t.string :body_digest, null: false
      t.string :media_digest, null: false
      t.datetime :reviewed_at, null: false

      t.timestamps
    end
    add_index :social_announcement_text_reviews,
      [:social_announcement_text_id, :body_digest, :media_digest, :reviewed_by_id],
      unique: true,
      name: "idx_satr_on_text_digests_and_reviewer"

    create_table :social_announcement_target_platforms do |t|
      t.references :social_announcement, null: false, foreign_key: true
      t.string :platform, null: false

      t.timestamps
    end
    add_index :social_announcement_target_platforms, [:social_announcement_id, :platform], unique: true

    create_table :social_announcement_media do |t|
      t.references :social_announcement, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.text :alt_text_ja
      t.text :alt_text_en

      t.timestamps
    end
    add_index :social_announcement_media, [:social_announcement_id, :position]

    create_table :social_announcement_posts do |t|
      t.references :social_announcement_text, null: false, foreign_key: true
      t.references :social_announcement_target_platform, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :remote_id
      t.string :remote_url
      t.text :posted_body
      t.string :posted_media_digest
      t.datetime :posted_at
      t.text :last_error
      t.datetime :last_error_at

      t.timestamps
    end
    add_index :social_announcement_posts,
      [:social_announcement_text_id, :social_announcement_target_platform_id],
      unique: true,
      name: "idx_sap_on_text_and_target_platform"

    create_table :social_oauth_tokens do |t|
      t.string :platform, null: false
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :access_token_expires_at, null: false
      t.string :screen_name, null: false
      t.string :remote_user_id, null: false
      t.string :scopes, null: false
      t.references :connected_by, null: false, foreign_key: {to_table: :users}
      t.datetime :connected_at, null: false

      t.timestamps
    end
    add_index :social_oauth_tokens, :platform, unique: true
  end
end
