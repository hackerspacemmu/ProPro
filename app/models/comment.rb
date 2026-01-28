class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :location, polymorphic: true

  attribute :deleted, :boolean, default: false

  validates :text, presence: { message: 'cannot be empty' }
end
