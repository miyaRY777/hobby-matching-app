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

ActiveRecord::Schema[7.2].define(version: 2026_02_17_062327) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "hobbies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hobbies_on_name", unique: true
  end

  create_table "profile_hobbies", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "hobby_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hobby_id"], name: "index_profile_hobbies_on_hobby_id"
    t.index ["profile_id", "hobby_id"], name: "index_profile_hobbies_on_profile_id_and_hobby_id", unique: true
    t.index ["profile_id"], name: "index_profile_hobbies_on_profile_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "issuer_profile_id", null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issuer_profile_id"], name: "index_rooms_on_issuer_profile_id"
  end

  create_table "share_links", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_share_links_on_room_id"
    t.index ["token"], name: "index_share_links_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nickname"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "profile_hobbies", "hobbies"
  add_foreign_key "profile_hobbies", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "rooms", "profiles", column: "issuer_profile_id"
  add_foreign_key "share_links", "rooms"
end
