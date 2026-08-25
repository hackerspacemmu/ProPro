class UserController < ApplicationController
  allow_unauthenticated_access only: %i[new create claim handle_claim]

  def resend_invite
    user = User.find(params[:id])
    if user.has_registered
      redirect_back_or_to '/', alert: 'User already registered'
      return
    end

    # Ensure OTP exists or recreate if missing (though it should exist for unregistered users)
    otp_instance = user.otp || Otp.create!(user: user, token: SecureRandom.uuid)

    GeneralMailer.with(
      email_address: user.email_address,
      otp_token: otp_instance.token
    ).ProPro_Invite.deliver_later

    redirect_back_or_to '/', notice: "Invitation resent to #{user.email_address}"
  end

  def new
  end

  def edit
    if params[:user][:name].blank?
      redirect_back_or_to '/', alert: 'Name cannot be empty'
      return
    end

    if params[:user][:new_password].present?
      if params[:user][:new_password_confirmation].blank? or params[:user][:new_password] != params[:user][:new_password_confirmation]
        redirect_back_or_to '/', alert: 'New passwords do not match'
        return
      elsif params[:user][:new_password].length > 72
        redirect_back_or_to '/', alert: 'Password must be less than 72 characters'
        return
      end
    end

    begin
      Current.user.update!(
        name: params[:user][:name],
        web_link: params[:user][:web_link],
        description: params[:user][:description]
      )

      Current.user.update!(password: params[:user][:new_password]) if params[:user][:new_password].present?
    rescue StandardError
      render :profile, status: :unprocessable_entity
      return
    end

    redirect_to user_profile_path, notice: 'Profile updated successfully'
  end

  def claim
    @email = Otp.find_by(token: params[:token]).user.email_address
  rescue StandardError
    redirect_to login_path, alert: "Invalid token, perhaps you've already claimed your account? Try logging in."
  end

  def handle_claim
    response = params.permit(:password, :password_confirmation, :name, :instid, :token)
    return if response[:token].blank?

    if response[:password].blank?
      redirect_back_or_to '/', alert: 'Password cannot be empty'
      return
    end

    if response[:password_confirmation].blank?
      redirect_back_or_to '/', alert: 'Password confirmation cannot be empty'
      return
    end

    if response[:instid].blank?
      redirect_back_or_to '/', alert: 'Institution ID cannot be empty'
      return
    end

    if response[:password] != response[:password_confirmation]
      redirect_back_or_to '/', alert: 'Passwords are not the same'
      return
    end

    if response[:password].length > 72
      redirect_back_or_to '/', alert: 'Password must be less than or equal to 72 characters'
      return
    end

    otp_instance = Otp.find_by(token: response[:token])

    unless otp_instance
      redirect_back_or_to '/', alert: 'Something went wrong'
      return
    end

    user = otp_instance.user

    if response[:name].blank?
      redirect_back_or_to '/', alert: 'Name cannot be empty'
      return
    end

    if user.update!(has_registered: true, password: response[:password], name: response[:name].strip, instid: response[:instid].strip)
      redirect_to '/session/new', notice: 'Account successfully claimed'
    else
      redirect_back_or_to '/', alert: 'Something went wrong'
    end

    user.otp.destroy
  end

  def create
    email = params.require(:email_address).strip

    if User.find_by(email_address: email)
      redirect_to user_profile_path, notice: "Your email is already in the system. Check your inbox or login!"
      return
    end

    begin
      ActiveRecord::Base.transaction do
        new_user = User.create!(
          email_address: email,
          name: "Placeholder Username",
          password: SecureRandom.base64(24),
          has_registered: false
        )

        new_otp_instance = Otp.create!(
          user: new_user,
          token: SecureRandom.uuid
        )
      end
    rescue StandardError => e
      redirect_back_or_to '/', alert: e.message
      return
    end

    new_user = User.find_by(email_address: email)

    GeneralMailer.with(
      email_address: new_user.email_address,
      otp_token: new_user.otp.token
    ).ProPro_Invite.deliver_later

    redirect_to login_path, notice: "Account created successfully. Check your inbox!"
  end

  def profile
    @user = Current.user
  end
end
