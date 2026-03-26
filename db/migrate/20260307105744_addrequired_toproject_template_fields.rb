class AddrequiredToprojectTemplateFields < ActiveRecord::Migration[8.0]
  def change
    add_column :project_template_fields, :required, :boolean, default: true
  end
end
