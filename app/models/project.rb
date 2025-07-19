class Project < ApplicationRecord
  belongs_to :enrolment, optional: true 
  belongs_to :owner, polymorphic: true
end
