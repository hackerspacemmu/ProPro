class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: -> (e) { e.strip.downcase }
  normalizes :username, with: -> (n) { n.strip }

  has_many :enrolments
  has_many :courses, through: :enrolments
  has_many :project_groups, through: :courses
  has_many :comments
  has_one :otp

  validates :email_address, presence: { message: "cannot be empty" }, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }

  def self.projects
    Ownership.where(owner_id: self.project_groups.ids, owner_type: :ProjectGroup).or(Ownership.where(owner_id: self.id, owner_type: :User))
  end
end
