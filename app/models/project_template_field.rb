class ProposalTemplateField < ApplicationRecord
  belongs_to :proposal_template

  enum field_type: {text: 0, textarea: 1, select: 2, radio: 3}
  enum applicable_to: {topic: 0, proposal: 1, all: 2}
end
