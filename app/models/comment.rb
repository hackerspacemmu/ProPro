class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :location, polymorphic: true

  attribute :deleted, :boolean, default: false
  #attribute :project_version_number, :integer, default: 1

  validates :text, presence: { message: "cannot be empty" }
  #validates :project_version_number, numericality: { only_integer: true, greater_than: 0 }
end
