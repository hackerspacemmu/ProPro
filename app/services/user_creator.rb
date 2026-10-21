require 'ostruct'

class UserCreator
  def self.call(name:, email:, password:, verify_only:, instid: nil)
    name = name.strip
    email = email.strip

    if instid
      instid = instid.strip
    end

    new_user = nil
    new_otp = nil

    begin
      ActiveRecord::Base.transaction do
        new_user = User.create!(
          name: name,
          email_address: email,
          password: password,
          instid: instid,
          has_registered: false
        )

        new_otp = Otp.create!(
          user: new_user,
          token: SecureRandom.uuid,
          verify_only: verify_only
        )
      end
    rescue ActiveRecord::RecordNotUnique
      return OpenStruct.new(success?: false, message: 'Your email is already in the system. Check your inbox or login!')
    rescue StandardError => e
      return OpenStruct.new(success?: false, message: e.message)
    end

    return OpenStruct.new(success?: true, user: new_user, otp_instance: new_otp)
  end
end
