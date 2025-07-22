class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :enrolments
  has_many :courses, through: :enrolments
  has_many :project_groups, through: :courses
  has_many :comments

  def self.projects
    Ownership.where(owner_id: self.project_groups.ids, owner_type: :ProjectGroup).or(Ownership.where(owner_id: self.id, owner_type: :User))
  end
end
