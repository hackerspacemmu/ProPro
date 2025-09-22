class AddPolymorphicLocationToComments < ActiveRecord::Migration[8.0]
  class Comment < ApplicationRecord
    belongs_to :location, polymorphic: true
  end

  def change
    add_reference :comments, :location, null: true, polymorphic: true
  end
end
