class AddDateToProgressUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :progress_updates, :date, :date
  end
end
