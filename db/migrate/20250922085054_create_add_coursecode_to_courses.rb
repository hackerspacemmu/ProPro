class CreateAddCoursecodeToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :coursecode, :string
    add_column :courses, :coursecode_url, :string
    
    add_index :courses, :coursecode, unique: true
  end
end
