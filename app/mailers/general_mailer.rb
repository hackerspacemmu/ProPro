class GeneralMailer < ApplicationMailer
  def ProPro_Invite
    @otp = params[:otp]
    @otp_token = params[:otp_token]
    @email_address = params[:email_address]
    @is_staff = params[:is_staff]
    mail(to: @email_address, Subject: 'Invitation for ProPro')
  end

  def Project_Status_Updated
    @course = params[:course]
    @project = params[:project]
    @supervisor_name = params[:supervisor_name]

    if @course.grouped?
      emails = @project.owner.project_group_members.joins(:user).pluck('user.email_address')
      @recipient = @project.owner.group_name
      mail(to: emails, Subject: 'Status Updated')
    else
      @recipient = @project.owner.name
      mail(to: @project.owner.email_address, Subject: 'Status Updated')
    end
  end

  def Topic_Status_Updated
    @course = params[:course]
    @topic = params[:topic]
    @supervisor_name = params[:supervisor_name]

    @recipient = @topic.owner.name
    mail(to: @topic.owner.email_address, Subject: 'Status Updated')
  end

  def New_Student_Submission
    @supervisor_name = params[:supervisor_name]
    @owner_name = params[:owner_name]
    @course = params[:course]
    @project = params[:project]

    mail(to: @project.supervisor.email_address, Subject: 'New Student Submission')
  end

  def Course_Invite_Notification
    @course = params[:course]
    @recipient = params[:email_address]

    mail(to: @recipient, Subject: "You've Been Added To A Course in ProPro")
  end

  def Project_Comment_Notification
    @course = params[:course]
    @project = params[:project]
    @recipient = params[:recipient]
    @commenter_name = params[:commenter_name]
    @comment_snippet = params[:comment_snippet]

    mail(to: params[:email_address], Subject: 'New Comment on Your Project')
  end

  def Group_Direct_Request_Notification
    @invite = params[:invite]
    @group = @invite.project_group
    @sender = @invite.sender

    raise ArgumentError, "Group_Direct_Request_Notification: group #{@group.id} has no leader_id" if @group.leader_id.blank?

    @leader = User.find(@group.leader_id)

    mail(to: @leader.email_address, Subject: "New join request for #{@group.group_name}")
  end

  def Group_Direct_Request_Accepted
    @invite = params[:invite]
    @group = @invite.project_group

    mail(to: @invite.sender.email_address, Subject: "Your request to join #{@group.group_name} was accepted")
  end

  def Group_Direct_Request_Declined
    @invite = params[:invite]
    @group = @invite.project_group

    mail(to: @invite.sender.email_address, Subject: "Your request to join #{@group.group_name} was declined")
  end

  def Group_Direct_Invite_Notification
    @invite = params[:invite]
    @group = @invite.project_group

    mail(to: @invite.recipient.email_address, Subject: "You've been invited to join #{@group.group_name}")
  end

  def Group_Direct_Invite_Accepted
    @invite = params[:invite]
    @group = @invite.project_group

    mail(to: @invite.sender.email_address, Subject: "#{@invite.recipient.name} accepted your invite to #{@group.group_name}")
  end

  def Group_Direct_Invite_Declined
    @invite = params[:invite]
    @group = @invite.project_group

    mail(to: @invite.sender.email_address, Subject: "#{@invite.recipient.name} declined your invite to #{@group.group_name}")
  end
end
