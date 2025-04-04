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

ActiveRecord::Schema[7.2].define(version: 2024_10_22_173205) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aspace_instances", force: :cascade do |t|
    t.string "slug", null: false
    t.string "base_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_aspace_instances_on_slug", unique: true
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "endpoints", force: :cascade do |t|
    t.string "slug", null: false
    t.string "public_contacts", array: true
    t.string "tech_contacts", array: true
    t.jsonb "last_harvest_results", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type", null: false
    t.text "webpage_url"
    t.integer "aspace_repo_id"
    t.bigint "aspace_instance_id"
    t.boolean "active", default: true, null: false
    t.index ["aspace_instance_id"], name: "index_endpoints_on_aspace_instance_id"
    t.index ["slug"], name: "index_endpoints_on_slug", unique: true
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "endpoints", "aspace_instances"
end
