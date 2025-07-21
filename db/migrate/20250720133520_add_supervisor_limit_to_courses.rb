class AddSupervisorLimitToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :supervised_max_underlings, :integer
  end
end
