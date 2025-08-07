class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  belongs_to :supervisor_enrolment, class_name: "Enrolment", foreign_key: "enrolment_id"

  has_many :project_instances, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  delegate :owner, to: :ownership

  def supervisor
    User.find(Enrolment.find(self.enrolment_id).user_id)
  end

  def status
    self.project_instances.last.status
  end

  def self.statuses
    ProjectInstance.statuses
  end

  def member
    if ownership.owner.is_a?(ProjectGroup)
      ownership.owner.users
    else
      [ ownership.user ]
    end
  end
end
