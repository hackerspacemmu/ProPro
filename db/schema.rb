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

ActiveRecord::Schema[8.0].define(version: 2025_07_15_105517) do
  create_table "courses", force: :cascade do |t|
    t.string "course_name", null: false
    t.integer "number_of_updates", null: false
    t.integer "starting_week", null: false
    t.boolean "student_access", null: false
    t.boolean "lecturer_access", null: false
    t.string "topic_suggestions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enrolments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_enrolments_on_course_id"
    t.index ["user_id"], name: "index_enrolments_on_user_id"
  end

  create_table "progress_updates", force: :cascade do |t|
    t.integer "proposal_id", null: false
    t.integer "rating", null: false
    t.string "feedback", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proposal_id"], name: "index_progress_updates_on_proposal_id"
  end

  create_table "project_group_members", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "project_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_project_group_members_on_course_id"
    t.index ["project_group_id"], name: "index_project_group_members_on_project_group_id"
    t.index ["user_id"], name: "index_project_group_members_on_user_id"
  end

  create_table "project_groups", force: :cascade do |t|
    t.string "group_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "proposals", force: :cascade do |t|
    t.integer "enrolment_id", null: false
    t.integer "project_group_id", null: false
    t.string "student_proposal", null: false
    t.string "feedback"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrolment_id"], name: "index_proposals_on_enrolment_id"
    t.index ["project_group_id"], name: "index_proposals_on_project_group_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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

  add_foreign_key "enrolments", "courses"
  add_foreign_key "enrolments", "users"
  add_foreign_key "progress_updates", "proposals"
  add_foreign_key "project_group_members", "courses"
  add_foreign_key "project_group_members", "project_groups"
  add_foreign_key "project_group_members", "users"
  add_foreign_key "proposals", "enrolments"
  add_foreign_key "proposals", "project_groups"
  add_foreign_key "sessions", "users"
end
