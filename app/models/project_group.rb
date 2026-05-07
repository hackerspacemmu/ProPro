class ProjectGroup < ApplicationRecord
  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner

  def can_confirm?
    if course.student_list_finalised?
      result = course.group_size_distribution
      return false if result.nil? || result[:error].present?

      result[:groups].map { |e| e[:size] }.include?(project_group_members.count)
    else
      project_group_members.count >= course.group_min.to_i && project_group_members.count <= course.group_max.to_i
    end
  end

  def confirm!
    return false unless can_confirm?

    update!(confirmed: true)
  end

  def add_member!(user, is_coordinator: false)
    transaction do
      raise StandardError, "Error: #{user.name} is already in a group for this course." if course.project_group_members.exists?(user: user)

      raise StandardError, "This group has reached the maximum limit of #{course.group_max} members." if !is_coordinator && (project_group_members.count >= course.group_max.to_i)

      project_group_members.create!(user: user)
    end
    true
  end

  def remove_member!(user)
    transaction do
      member = project_group_members.find_by(user: user)
      return false unless member

      member.destroy!

      if project_group_members.reload.count.zero?
        destroy!
      elsif !can_confirm? && confirmed?
        revert_to_draft!
      end
    end
    true
  end

  def revert_to_draft!
    update!(confirmed: false)
  end

  # coordinator can force confirm regardless of the value of can_confirm
  def force_confirm!
    update!(confirmed: true)
  end
end
