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

ActiveRecord::Schema[8.0].define(version: 2024_10_14_155515) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "authentication_provider_email_and_passwords", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_authentication_provider_email_and_passwords_on_email", unique: true
    t.index ["user_id"], name: "index_authentication_provider_email_and_passwords_on_user_id"
  end

  create_table "authentication_provider_githubs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_authentication_provider_githubs_on_uid", unique: true
    t.index ["user_id"], name: "index_authentication_provider_githubs_on_user_id"
  end

  create_table "cloudflare_stream_live_streams", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "uid", null: false
    t.string "name", null: false
    t.jsonb "stream_raw_response"
    t.jsonb "stream_videos_raw_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_cloudflare_stream_live_streams_on_event_id"
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

  create_table "ongoing_events", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_ongoing_events_on_event_id"
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

  create_table "signage_device_assigns", id: false, force: :cascade do |t|
    t.bigint "signage_panel_id", null: false
    t.bigint "signage_device_id", null: false
    t.index ["signage_device_id"], name: "index_signage_device_assigns_on_signage_device_id"
    t.index ["signage_panel_id"], name: "index_signage_device_assigns_on_signage_panel_id"
  end

  create_table "signage_devices", force: :cascade do |t|
    t.string "device_name", null: false
    t.datetime "last_heaetbeated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "signage_pages", force: :cascade do |t|
    t.bigint "signage_schedule_id", null: false
    t.integer "order", null: false
    t.integer "duration_second", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["signage_schedule_id"], name: "index_signage_pages_on_signage_schedule_id"
  end

  create_table "signage_panels", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "signage_schedule_assigns", id: false, force: :cascade do |t|
    t.bigint "signage_schedule_id", null: false
    t.bigint "signage_panel_id", null: false
    t.index ["signage_panel_id"], name: "index_signage_schedule_assigns_on_signage_panel_id"
    t.index ["signage_schedule_id"], name: "index_signage_schedule_assigns_on_signage_schedule_id"
  end

  create_table "signage_schedules", force: :cascade do |t|
    t.bigint "signage_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["signage_id"], name: "index_signage_schedules_on_signage_id"
  end

  create_table "signages", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_signages_on_event_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
  add_foreign_key "authentication_provider_email_and_passwords", "users"
  add_foreign_key "authentication_provider_githubs", "users"
  add_foreign_key "cloudflare_stream_live_streams", "events"
  add_foreign_key "ongoing_events", "events"
  add_foreign_key "profile_exchanges", "events"
  add_foreign_key "profile_exchanges", "users"
  add_foreign_key "profile_exchanges", "users", column: "friend_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "signage_pages", "signage_schedules"
  add_foreign_key "signage_schedules", "signages"
  add_foreign_key "signages", "events"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "talk_bookmarks", "talks"
  add_foreign_key "talk_bookmarks", "users"
  add_foreign_key "talk_reminders", "talks"
  add_foreign_key "talk_reminders", "users"
  add_foreign_key "unread_announcements", "announcements"
  add_foreign_key "unread_announcements", "users"
  add_foreign_key "webpush_subscriptions", "users"
end
