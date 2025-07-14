class Proposal < ApplicationRecord
    belongs_to :group
    belongs_to :user
    enum :status, { pending: 0, approved: 1, rejected: 2 }
end
