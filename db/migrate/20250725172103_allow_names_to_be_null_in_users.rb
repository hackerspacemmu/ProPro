class AllowNamesToBeNullInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :username, true
  end
end
