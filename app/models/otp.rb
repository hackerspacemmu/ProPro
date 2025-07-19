class Otp < ApplicationRecord
    validates :email_address, uniqueness: true
end
