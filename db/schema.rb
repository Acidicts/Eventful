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

ActiveRecord::Schema[8.1].define(version: 2026_03_21_123001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", default: "local", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.integer "event_id"
    t.integer "organisation_id", null: false
    t.boolean "public"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_announcements_on_creator_id"
    t.index ["event_id"], name: "index_announcements_on_event_id"
    t.index ["organisation_id"], name: "index_announcements_on_organisation_id"
  end

  create_table "attendees", force: :cascade do |t|
    t.integer "age"
    t.string "allergies"
    t.integer "attendance", default: 0
    t.boolean "attending", default: false, null: false
    t.string "ban_reason"
    t.boolean "banned", default: false, null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "diet", default: 0, null: false
    t.string "email"
    t.integer "event_id"
    t.string "ip"
    t.string "name"
    t.string "other_diet", default: "", null: false
    t.string "parent_signature"
    t.integer "status"
    t.boolean "under_18", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "waiver_signature"
    t.boolean "waiver_signed", default: false, null: false
    t.datetime "waiver_signed_at"
    t.index ["event_id"], name: "index_attendees_on_event_id"
  end

  create_table "attendence_changes", force: :cascade do |t|
    t.integer "attendee_id", null: false
    t.integer "attendence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendee_id"], name: "index_attendence_changes_on_attendee_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "details", default: "{}", null: false
    t.string "ip_address"
    t.string "path", null: false
    t.string "request_method", null: false
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "email_login_otps", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "user_id", null: false
    t.index ["code"], name: "index_email_login_otps_on_code"
    t.index ["token"], name: "index_email_login_otps_on_token", unique: true
    t.index ["user_id"], name: "index_email_login_otps_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "applied"
    t.string "apply_token"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "end_date"
    t.boolean "finished", default: false, null: false
    t.string "location", default: "TBA"
    t.string "name"
    t.integer "organisation_id", null: false
    t.integer "organiser_id"
    t.datetime "start_date"
    t.datetime "updated_at", null: false
    t.index ["apply_token"], name: "index_events_on_apply_token", unique: true
    t.index ["organisation_id"], name: "index_events_on_organisation_id"
    t.index ["organiser_id"], name: "index_events_on_organiser_id"
  end

  create_table "galleries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organisation_id", null: false
    t.boolean "public"
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_galleries_on_organisation_id"
  end

  create_table "gallery_images", force: :cascade do |t|
    t.integer "attendee_id", null: false
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "day_from"
    t.integer "gallery_id", null: false
    t.datetime "updated_at", null: false
    t.index ["attendee_id"], name: "index_gallery_images_on_attendee_id"
    t.index ["gallery_id"], name: "index_gallery_images_on_gallery_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "answer"
    t.integer "answerer_id"
    t.datetime "created_at", null: false
    t.string "message"
    t.boolean "read", default: false
    t.integer "reciever_id", null: false
    t.string "reciever_type"
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["answerer_id"], name: "index_messages_on_answerer_id"
    t.index ["reciever_id"], name: "index_messages_on_reciever_id"
    t.index ["reciever_type", "reciever_id"], name: "index_messages_on_reciever_type_and_reciever_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "organisation_applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_organisation_applications_on_user_id"
  end

  create_table "organisation_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default_role", default: false, null: false
    t.string "name", default: "", null: false
    t.integer "organisation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id", "name"], name: "index_organisation_roles_on_organisation_and_name", unique: true
    t.index ["organisation_id"], name: "index_organisation_roles_on_organisation_id"
  end

  create_table "organisation_roles_role_permissions", id: false, force: :cascade do |t|
    t.integer "organisation_role_id", null: false
    t.integer "role_permission_id", null: false
    t.index ["organisation_role_id", "role_permission_id"], name: "index_org_roles_role_perms_on_role_and_perm", unique: true
  end

  create_table "organisation_roles_users", id: false, force: :cascade do |t|
    t.integer "organisation_role_id", null: false
    t.integer "user_id", null: false
    t.index ["organisation_role_id", "user_id"], name: "index_organisation_roles_users_on_org_role_and_user", unique: true
  end

  create_table "organisations", force: :cascade do |t|
    t.integer "child_org_id"
    t.datetime "created_at", null: false
    t.time "default_event_end_time", default: "2000-01-01 15:00:00"
    t.integer "default_event_length", default: 2
    t.string "default_event_location", default: "", null: false
    t.time "default_event_start_time", default: "2000-01-01 10:00:00"
    t.string "default_event_title"
    t.string "default_online_event_url", default: "https://eventful.bing-bong.uk"
    t.text "description"
    t.boolean "eventful_branding", default: true, null: false
    t.string "img"
    t.string "join_requirements"
    t.string "name", default: "Unamed Organisation", null: false
    t.boolean "nil_org", default: false, null: false
    t.integer "parent_org_id"
    t.string "primary_color"
    t.string "secondary_color"
    t.boolean "self_found", default: false, null: false
    t.integer "signing_user_id"
    t.integer "time_utc_offset", default: 0
    t.string "timezone", default: "UTC"
    t.boolean "top_level_org", default: true, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["child_org_id"], name: "index_organisations_on_child_org_id"
    t.index ["parent_org_id"], name: "index_organisations_on_parent_org_id"
    t.index ["signing_user_id"], name: "index_organisations_on_signing_user_id"
    t.index ["user_id"], name: "index_organisations_on_user_id"
  end

  create_table "photos", force: :cascade do |t|
    t.integer "attendee_id", null: false
    t.string "caption"
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["attendee_id"], name: "index_photos_on_attendee_id"
    t.index ["event_id"], name: "index_photos_on_event_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "expires_at"
    t.integer "favorite_org_id"
    t.string "name"
    t.integer "organisation_id"
    t.string "provider", null: false
    t.string "refresh_token"
    t.string "role", default: "user", null: false
    t.string "slack_id"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "verification_status"
    t.index ["access_token"], name: "index_users_on_access_token"
    t.index ["email"], name: "index_users_on_email"
    t.index ["favorite_org_id"], name: "index_users_on_favorite_org_id"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "events"
  add_foreign_key "announcements", "organisations"
  add_foreign_key "announcements", "users", column: "creator_id"
  add_foreign_key "attendees", "events"
  add_foreign_key "attendence_changes", "attendees"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "email_login_otps", "users"
  add_foreign_key "events", "organisations"
  add_foreign_key "events", "users", column: "organiser_id"
  add_foreign_key "galleries", "organisations"
  add_foreign_key "gallery_images", "attendees"
  add_foreign_key "gallery_images", "galleries"
  add_foreign_key "messages", "users", column: "answerer_id"
  add_foreign_key "organisation_applications", "users"
  add_foreign_key "organisation_roles", "organisations"
  add_foreign_key "organisation_roles_role_permissions", "organisation_roles"
  add_foreign_key "organisation_roles_role_permissions", "role_permissions"
  add_foreign_key "organisation_roles_users", "organisation_roles"
  add_foreign_key "organisation_roles_users", "users"
  add_foreign_key "organisations", "organisations", column: "child_org_id"
  add_foreign_key "organisations", "organisations", column: "parent_org_id"
  add_foreign_key "organisations", "users"
  add_foreign_key "organisations", "users", column: "signing_user_id"
  add_foreign_key "photos", "attendees"
  add_foreign_key "photos", "events"
  add_foreign_key "users", "organisations"
  add_foreign_key "users", "organisations", column: "favorite_org_id"
end
