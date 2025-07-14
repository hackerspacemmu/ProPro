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

ActiveRecord::Schema[8.0].define(version: 2025_07_14_151105) do
  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_enrollments_on_group_id"
    t.index ["subject_id"], name: "index_enrollments_on_subject_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "group_name", null: false
    t.integer "group_role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "progress_updates", force: :cascade do |t|
    t.integer "proposal_id", null: false
    t.integer "rating", null: false
    t.string "feedback", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proposal_id"], name: "index_progress_updates_on_proposal_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.string "student_proposal", null: false
    t.string "instructor_feedback"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_proposals_on_group_id"
    t.index ["user_id"], name: "index_proposals_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "subject_name", null: false
    t.integer "number_of_updates", null: false
    t.integer "starting_week", null: false
    t.boolean "restricted_view", null: false
    t.string "topic_suggestions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest"
    t.string "username", null: false
    t.boolean "has_registered", null: false
    t.string "student_id"
    t.string "mmu_directory"
    t.boolean "is_staff", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "enrollments", "groups"
  add_foreign_key "enrollments", "subjects"
  add_foreign_key "enrollments", "users"
  add_foreign_key "progress_updates", "proposals"
  add_foreign_key "proposals", "groups"
  add_foreign_key "proposals", "users"
  add_foreign_key "sessions", "users"
end
