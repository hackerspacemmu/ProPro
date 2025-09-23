class ProgressUpdate < ApplicationRecord
    belongs_to :project
    enum :rating, { no_progress: 1, unsatisfactory: 2, satisfactory: 3 , excellent: 4}
    has_many :comments, as: :location

    validates :rating, presence: { message: "cannot be empty" }
    validates :feedback, presence: { message: "cannot be empty" }
    validates :date, presence: { message: "cannot be empty" }
end
