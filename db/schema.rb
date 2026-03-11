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

ActiveRecord::Schema[8.1].define(version: 2026_03_11_230946) do
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

  create_table "attendees", force: :cascade do |t|
    t.integer "age"
    t.string "allergies"
    t.integer "attendance", default: 0
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

  create_table "events", force: :cascade do |t|
    t.integer "applied"
    t.string "apply_token"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "end_date"
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

  create_table "organisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "eventful_branding", default: true, null: false
    t.string "img"
    t.string "name", default: "Unamed Organisation", null: false
    t.boolean "self_found", default: false, null: false
    t.integer "signing_user_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["signing_user_id"], name: "index_organisations_on_signing_user_id"
    t.index ["user_id"], name: "index_organisations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "expires_at"
    t.string "name"
    t.integer "organisation_id"
    t.string "organisation_role", default: "member", null: false
    t.string "provider", null: false
    t.string "refresh_token"
    t.string "role", default: "user", null: false
    t.string "slack_id"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "verification_status"
    t.index ["access_token"], name: "index_users_on_access_token"
    t.index ["email"], name: "index_users_on_email"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["organisation_role"], name: "index_users_on_organisation_role"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendees", "events"
  add_foreign_key "events", "organisations"
  add_foreign_key "events", "users", column: "organiser_id"
  add_foreign_key "organisations", "users"
  add_foreign_key "organisations", "users", column: "signing_user_id"
  add_foreign_key "users", "organisations"
end
