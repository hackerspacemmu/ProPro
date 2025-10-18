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

ActiveRecord::Schema[8.0].define(version: 2025_10_01_144548) do
  create_table "comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "location_type", null: false
    t.integer "location_id", null: false
    t.index ["location_type", "location_id"], name: "index_comments_on_location"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "course_name", null: false
    t.integer "number_of_updates"
    t.integer "starting_week", null: false
    t.boolean "grouped", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supervisor_projects_limit", null: false
    t.boolean "require_coordinator_approval", null: false
    t.integer "student_access", null: false
    t.boolean "lecturer_access", null: false
    t.boolean "use_progress_updates", null: false
    t.string "course_description"
    t.string "file_link"
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

  create_table "otps", force: :cascade do |t|
    t.string "otp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_otps_on_user_id"
  end

  create_table "progress_updates", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "rating", null: false
    t.string "feedback", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.index ["project_id"], name: "index_progress_updates_on_project_id"
  end

  create_table "project_group_members", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_group_id"], name: "index_project_group_members_on_project_group_id"
    t.index ["user_id"], name: "index_project_group_members_on_user_id"
  end

  create_table "project_groups", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "group_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_project_groups_on_course_id"
  end

  create_table "project_instance_fields", force: :cascade do |t|
    t.integer "project_instance_id"
    t.integer "project_template_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "instance_type"
    t.integer "instance_id"
    t.index ["instance_type", "instance_id"], name: "index_project_instance_fields_on_instance"
    t.index ["project_instance_id", "project_template_field_id"], name: "index_project_instance_fields_on_instance_and_template_field", unique: true
    t.index ["project_instance_id"], name: "index_project_instance_fields_on_project_instance_id"
    t.index ["project_template_field_id"], name: "index_project_instance_fields_on_project_template_field_id"
  end

  create_table "project_instances", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "version", null: false
    t.integer "created_by_id", null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.integer "enrolment_id"
    t.integer "source_topic_id"
    t.integer "project_instance_type", null: false
    t.datetime "last_status_change_time"
    t.datetime "last_edit_time"
    t.integer "last_status_change_by"
    t.integer "last_edit_by"
    t.index ["created_by_id"], name: "index_project_instances_on_created_by_id"
    t.index ["enrolment_id"], name: "index_project_instances_on_enrolment_id"
    t.index ["project_id", "version"], name: "index_project_instances_on_project_id_and_version", unique: true
    t.index ["project_id"], name: "index_project_instances_on_project_id"
    t.index ["source_topic_id"], name: "index_project_instances_on_source_topic_id"
  end

  create_table "project_template_fields", force: :cascade do |t|
    t.integer "project_template_id", null: false
    t.integer "field_type", null: false
    t.integer "applicable_to", null: false
    t.string "label", null: false
    t.text "hint"
    t.json "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_template_id"], name: "index_project_template_fields_on_project_template_id"
  end

  create_table "project_templates", force: :cascade do |t|
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["course_id"], name: "index_project_templates_on_course_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "enrolment_id"
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.string "owner_type"
    t.integer "owner_id"
    t.integer "ownership_type"
    t.index ["course_id"], name: "index_projects_on_course_id"
    t.index ["enrolment_id"], name: "index_projects_on_enrolment_id"
    t.index ["owner_type", "owner_id"], name: "index_projects_on_owner"
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
    t.string "password_digest", null: false
    t.string "username", null: false
    t.boolean "has_registered", null: false
    t.string "student_id"
    t.string "web_link"
    t.boolean "is_staff", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "comments", "users"
  add_foreign_key "enrolments", "courses"
  add_foreign_key "enrolments", "users"
  add_foreign_key "otps", "users"
  add_foreign_key "progress_updates", "projects"
  add_foreign_key "project_group_members", "project_groups"
  add_foreign_key "project_group_members", "users"
  add_foreign_key "project_groups", "courses"
  add_foreign_key "project_instance_fields", "project_instances"
  add_foreign_key "project_instance_fields", "project_template_fields"
  add_foreign_key "project_instances", "enrolments"
  add_foreign_key "project_instances", "projects"
  add_foreign_key "project_instances", "users", column: "created_by_id"
  add_foreign_key "project_template_fields", "project_templates"
  add_foreign_key "project_templates", "courses"
  add_foreign_key "projects", "courses"
  add_foreign_key "projects", "enrolments"
  add_foreign_key "sessions", "users"
end
