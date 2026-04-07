class AddCoursecodeEnabledToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :coursecode_enabled, :boolean, null: false, default: false
  end
end
