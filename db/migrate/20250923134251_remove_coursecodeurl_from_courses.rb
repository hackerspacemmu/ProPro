class Removecoursecodeurlfromcourses < ActiveRecord::Migration[8.0]
  def change
    remove_column :courses, :coursecode_url, :string
  end
end
