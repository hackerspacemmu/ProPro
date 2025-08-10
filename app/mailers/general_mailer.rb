class GeneralMailer < ApplicationMailer
    def ProPro_Invite
      @otp = params[:otp]
      @otp_token = params[:otp_token]
      @email_address = params[:email_address]
      @is_staff = params[:is_staff]
      mail(to: @email_address, Subject: "Invitation for ProPro")
    end
end
