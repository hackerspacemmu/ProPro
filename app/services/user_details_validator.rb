require 'ostruct'

class UserDetailsValidator
  def self.call(name:, password:, password_confirmation:)
    if name.blank?
      return OpenStruct.new(success?: false, message: 'Name cannot be empty')
    end

    if password.blank?
      return OpenStruct.new(success?: false, message: 'Password cannot be empty')
    end

    if password_confirmation.blank?
      return OpenStruct.new(success?: false, message: 'Password confirmation cannot be empty')
    end

    if password != password_confirmation
      return OpenStruct.new(success?: false, message: 'Passwords are not the same')
    end

    return OpenStruct.new(success?: true)
  end
end
