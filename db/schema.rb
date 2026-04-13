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

ActiveRecord::Schema[7.2].define(version: 2026_04_14_090003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "hobbies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_name"
    t.index ["name"], name: "index_hobbies_on_name", unique: true
    t.index ["normalized_name"], name: "index_hobbies_on_normalized_name"
  end

  create_table "hobby_parent_tags", force: :cascade do |t|
    t.bigint "hobby_id", null: false
    t.bigint "parent_tag_id", null: false
    t.integer "room_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hobby_id", "parent_tag_id"], name: "index_hobby_parent_tags_on_hobby_id_and_parent_tag_id", unique: true
    t.index ["hobby_id", "room_type"], name: "index_hobby_parent_tags_on_hobby_id_and_room_type", unique: true
    t.index ["hobby_id"], name: "index_hobby_parent_tags_on_hobby_id"
    t.index ["parent_tag_id", "room_type"], name: "index_hobby_parent_tags_on_parent_tag_id_and_room_type"
    t.index ["parent_tag_id"], name: "index_hobby_parent_tags_on_parent_tag_id"
  end

  create_table "parent_tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "room_type"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_type", "name"], name: "index_parent_tags_on_room_type_and_name", unique: true
    t.index ["room_type", "slug"], name: "index_parent_tags_on_room_type_and_slug", unique: true
  end

  create_table "profile_hobbies", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "hobby_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description", limit: 200
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

  create_table "room_memberships", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_room_memberships_on_profile_id"
    t.index ["room_id", "profile_id"], name: "index_room_memberships_on_room_id_and_profile_id", unique: true
    t.index ["room_id"], name: "index_room_memberships_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "issuer_profile_id", null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "room_type", default: 0, null: false
    t.boolean "locked", default: false, null: false
    t.index ["issuer_profile_id"], name: "index_rooms_on_issuer_profile_id"
  end

  create_table "share_links", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.string "token", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "expires_in"
    t.index ["room_id"], name: "index_share_links_on_room_id", unique: true
    t.index ["token"], name: "index_share_links_on_token", unique: true
  end

  create_table "social_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_social_accounts_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_social_accounts_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_social_accounts_on_user_id"
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
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "hobby_parent_tags", "hobbies"
  add_foreign_key "hobby_parent_tags", "parent_tags"
  add_foreign_key "profile_hobbies", "hobbies"
  add_foreign_key "profile_hobbies", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "room_memberships", "profiles"
  add_foreign_key "room_memberships", "rooms"
  add_foreign_key "rooms", "profiles", column: "issuer_profile_id"
  add_foreign_key "share_links", "rooms"
  add_foreign_key "social_accounts", "users"
end
