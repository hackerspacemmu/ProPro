class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  has_many :enrolments, dependent: :destroy
  has_many :courses, through: :enrolments

  # sort cards by earliest enrolment (coordinators can have multiple).
  def courses_by_earliest_enrolment
    Course.joins(:enrolments)
          .where(enrolments: { user_id: id })
          .group('courses.id')
          .order(Arel.sql('MIN(enrolments.created_at) DESC, courses.id DESC'))
  end

  has_many :project_group_members, dependent: :destroy
  has_many :project_groups, through: :project_group_members

  has_many :comments, dependent: :destroy
  has_one :otp, dependent: :destroy

  has_many :solo_projects, as: :owner, class_name: 'Project'
  has_many :group_projects, through: :project_groups, source: :project

  validates :email_address, presence: { message: 'cannot be empty' }, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
  validates :password, length: { maximum: 72, message: 'must be less than 72 characters' }
end
