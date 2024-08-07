# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_05_14_051356) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.index ["event_id"], name: "index_announcements_on_event_id"
  end

  create_table "authentication_provider_githubs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_authentication_provider_githubs_on_uid", unique: true
    t.index ["user_id"], name: "index_authentication_provider_githubs_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "profile_badges", force: :cascade do |t|
    t.string "text", null: false
    t.string "border_color_code", null: false
    t.string "background_color_code", null: false
    t.boolean "restricted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["text"], name: "index_profile_badges_on_text", unique: true
  end

  create_table "profile_badges_profiles", id: false, force: :cascade do |t|
    t.bigint "profile_badge_id", null: false
    t.bigint "profile_id", null: false
    t.index ["profile_id"], name: "index_profile_badges_profiles_on_profile_id"
  end

  create_table "profile_exchanges", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.bigint "friend_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_profile_exchanges_on_event_id"
    t.index ["friend_id"], name: "index_profile_exchanges_on_friend_id"
    t.index ["user_id"], name: "index_profile_exchanges_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "speakers", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "github_username", null: false
    t.string "gravatar_hash"
    t.text "bio", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_speakers_on_slug", unique: true
  end

  create_table "speakers_talks", id: false, force: :cascade do |t|
    t.bigint "speaker_id", null: false
    t.bigint "talk_id", null: false
    t.index ["speaker_id"], name: "index_speakers_talks_on_speaker_id"
    t.index ["talk_id"], name: "index_speakers_talks_on_talk_id"
  end

  create_table "talk_bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "talk_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["talk_id"], name: "index_talk_bookmarks_on_talk_id"
    t.index ["user_id", "talk_id"], name: "index_talk_bookmarks_on_user_id_and_talk_id", unique: true
    t.index ["user_id"], name: "index_talk_bookmarks_on_user_id"
  end

  create_table "talk_reminders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "talk_id", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["talk_id"], name: "index_talk_reminders_on_talk_id"
    t.index ["user_id"], name: "index_talk_reminders_on_user_id"
  end

  create_table "talks", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "title", null: false
    t.text "abstract", default: "", null: false
    t.datetime "start_at", null: false
    t.integer "duration_minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "track", null: false
    t.index ["event_id"], name: "index_talks_on_event_id"
  end

  create_table "unread_announcements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "announcement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_unread_announcements_on_announcement_id"
    t.index ["user_id", "announcement_id"], name: "index_unread_announcements_on_user_id_and_announcement_id", unique: true
    t.index ["user_id"], name: "index_unread_announcements_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "role", default: "participant", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "webpush_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.string "auth_key", null: false
    t.string "p256dh_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webpush_subscriptions_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authentication_provider_githubs", "users"
  add_foreign_key "profile_exchanges", "events"
  add_foreign_key "profile_exchanges", "users"
  add_foreign_key "profile_exchanges", "users", column: "friend_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "talk_bookmarks", "talks"
  add_foreign_key "talk_bookmarks", "users"
  add_foreign_key "talk_reminders", "talks"
  add_foreign_key "talk_reminders", "users"
  add_foreign_key "unread_announcements", "announcements"
  add_foreign_key "unread_announcements", "users"
  add_foreign_key "webpush_subscriptions", "users"
end
