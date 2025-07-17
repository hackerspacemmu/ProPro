class ProposalTemplate < ApplicationRecord
  belongs_to :course
  has_many :proposal_template_fields, dependent: :destroy
end
