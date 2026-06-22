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

ActiveRecord::Schema[8.0].define(version: 2026_06_20_135458) do
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
    t.string "coursecode"
    t.boolean "coursecode_enabled", default: false, null: false
    t.boolean "toggle_topics", default: true
    t.boolean "grouping_enabled", default: false, null: false
    t.boolean "student_list_finalised", default: false, null: false
    t.integer "group_min"
    t.integer "group_max"
    t.boolean "grouping_open", default: false, null: false
    t.datetime "grouping_opens_at"
    t.datetime "grouping_closes_at"
    t.boolean "supervisor_variable_capacity_enabled", default: false, null: false
    t.boolean "supervisor_auto_calculate_enabled", default: false, null: false
    t.index ["coursecode"], name: "index_courses_on_coursecode", unique: true
  end

  create_table "enrolments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supervisor_capacity_offset", default: 0, null: false
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

  create_table "ownerships", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.integer "ownership_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_ownerships_on_owner"
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

  create_table "project_group_invites", force: :cascade do |t|
    t.integer "project_group_id", null: false
    t.integer "sender_id", null: false
    t.integer "kind", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_group_id"], name: "index_project_group_invites_on_project_group_id"
    t.index ["sender_id", "project_group_id", "kind"], name: "idx_pgi_unique_pending_sender_group_kind", unique: true, where: "status = 0"
    t.index ["sender_id"], name: "index_project_group_invites_on_sender_id"
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
    t.boolean "confirmed", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.integer "leader_id"
    t.integer "course_group_sequence"
    t.index ["course_id", "course_group_sequence"], name: "index_project_groups_on_course_id_and_course_group_sequence", unique: true
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
    t.boolean "required", default: true
    t.boolean "free_edit", default: false, null: false
    t.integer "position", null: false
    t.boolean "is_project_title", default: false, null: false
    t.index ["project_template_id", "position"], name: "idx_on_project_template_id_position_8020fb7a17"
    t.index ["project_template_id"], name: "index_project_template_fields_on_project_template_id"
  end

