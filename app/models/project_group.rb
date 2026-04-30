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

  def revert_to_draft!
    update!(confirmed: false)
  end
end
