class MakeProjectInstanceFieldPolymorphic < ActiveRecord::Migration[8.0]
  def change
    add_reference :project_instance_fields, :instance, null: true, polymorphic: true
  end
end
