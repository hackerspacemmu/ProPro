class Proposal < ApplicationRecord
    belongs_to :project_group
    belongs_to :enrolment
    enum :status, { pending: 0, approved: 1, rejected: 2 }
end
