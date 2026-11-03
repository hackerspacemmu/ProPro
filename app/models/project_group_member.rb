class ProjectGroupMember < ApplicationRecord
  belongs_to :user
  belongs_to :project_group, touch: true
  belongs_to :course

  before_validation :set_course, on: :create

  # Returns false when the user is already in a group of this course.
  # The savepoint keeps the failed insert from aborting the caller's transaction.
  def self.add(user:, group:)
    transaction(requires_new: true) { create!(user: user, project_group: group) }
  rescue ActiveRecord::RecordNotUnique
    false
  end

  private

  def set_course
    self.course_id ||= project_group&.course_id
  end
end
