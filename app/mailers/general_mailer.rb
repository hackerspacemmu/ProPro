class GeneralMailer < ApplicationMailer
    def ProPro_Invite
      @otp = params[:otp]
      @otp_token = params[:otp_token]
      @email_address = params[:email_address]
      @is_staff = params[:is_staff]
      mail(to: @email_address, Subject: "Invitation for ProPro")
    end

    def Status_Updated
      @course = params[:course]
      @project = params[:project]
      @supervisor_username = params[:supervisor_username]

      if @course.grouped?
        emails = @project.owner.project_group_members.joins(:user).pluck("user.email_address")
        @recipient = @project.owner.group_name
        mail(to: emails, Subject: "Status Updated")
      else
        @recipient = @project.owner.username
        mail(to: @project.owner.email_address, Subject: "Status Updated")
      end
    end

    def New_Student_Submission
      @supervisor_username = params[:supervisor_username]
      @owner_name = params[:owner_name]
      @course = params[:course]
      @project = params[:project]

      mail(to: @project.supervisor.email_address, Subject: "New Student Submission")
    end
end
