class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :text, presence: { message: "cannot be empty" }
end
