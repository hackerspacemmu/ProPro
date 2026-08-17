class GeneralMailerPreview < ActionMailer::Preview
  def project_comment_notification
    comment = Comment.last
    project_instance = comment.location
    project = project_instance.project

    GeneralMailer.with(
      email_address: 'muzzammil.hakim.bin.norhazimi@test.com',
      recipient: 'Leong Yee Ling',
      commenter_name: 'Kevin Chong Wei Keong',
      comment_snippet: comment.text.truncate(50),
      course: project.course,
      project: project
    ).Project_Comment_Notification
  end
end