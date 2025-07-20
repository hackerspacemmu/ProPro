class GeneralMailer < ApplicationMailer
    default from: "example@example.com"

    def send_otp
      @otp_instance = Otp.find_by(email_address: params[:email_address])
      mail(to: @otp_instance.email_address, Subject: "OTP for ProPro")
    end
end
