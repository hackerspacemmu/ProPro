class Proposal < ApplicationRecord
  belongs_to :enrolment
  belongs_to :owner, polymorphic: true
end
