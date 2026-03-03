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

ActiveRecord::Schema[8.1].define(version: 2026_03_03_180000) do
  create_table "organisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "events_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["events_id"], name: "index_organisations_on_events_id"
    t.index ["user_id"], name: "index_organisations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "access_token"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "expires_at"
    t.string "name"
    t.integer "organisation_id"
    t.string "provider", null: false
    t.string "refresh_token"
    t.string "slack_id"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "verification_status"
    t.index ["access_token"], name: "index_users_on_access_token"
    t.index ["email"], name: "index_users_on_email"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "organisations", "events", column: "events_id"
  add_foreign_key "organisations", "users"
  add_foreign_key "users", "organisations"
end
