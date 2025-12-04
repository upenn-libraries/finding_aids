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

ActiveRecord::Schema[8.1].define(version: 2025_12_01_153345) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "aspace_instances", force: :cascade do |t|
    t.string "base_url", null: false
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.float "throttle"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_aspace_instances_on_slug", unique: true
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.string "user_type"
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "endpoints", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "aspace_instance_id"
    t.integer "aspace_repo_id"
    t.datetime "created_at", null: false
    t.jsonb "last_harvest_results", default: {}
    t.string "public_contacts", array: true
    t.string "slug", null: false
    t.string "source_type", null: false
    t.string "tech_contacts", array: true
    t.datetime "updated_at", null: false
    t.text "webpage_url"
    t.index ["aspace_instance_id"], name: "index_endpoints_on_aspace_instance_id"
    t.index ["slug"], name: "index_endpoints_on_slug", unique: true
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.binary "query_params"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "endpoints", "aspace_instances"
end
