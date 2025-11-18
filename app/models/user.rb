 class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: -> (e) { e.strip.downcase }
  normalizes :username, with: -> (n) { n.strip }

  has_many :enrolments, dependent: :destroy
  has_many :courses, through: :enrolments

  has_many :project_group_members
  has_many :project_groups, through: :project_group_members

  has_many :comments, dependent: :destroy
  has_one :otp, dependent: :destroy

  has_many :solo_projects, as: :owner, class_name: 'Project'
  has_many :group_projects, through: :project_groups, source: :project

  validates :email_address, presence: { message: "cannot be empty" }, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
  validates :password, length: { maximum: 72, message: "must be less than 72 characters" }

end
