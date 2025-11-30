class PasswordsMailer < ApplicationMailer
  default from: "noreply@propro.click"

  def reset(user)
    @user = user
    mail subject: "Reset your password", to: user.email_address
  end
end
