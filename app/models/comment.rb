class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :project

  attribute :deleted, :boolean, default: false
  validates :text, presence: { message: "cannot be empty" }
end
