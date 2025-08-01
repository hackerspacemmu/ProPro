class GeneralMailer < ApplicationMailer
    default from: "example@example.com"

    def send_student_invite
      @otp = params[:otp]
      @otp_token = params[:otp_token]
      @email_address = params[:email_address]
      mail(to: @email_address, Subject: "Invitation for ProPro")
    end

    def send_lecturer_invite
      @otp = params[:otp]
      @otp_token = params[:otp_token]
      @email_address = params[:email_address]
      mail(to: @email_address, Subject: "Invitation for ProPro")
    end
end
