class UserController < ApplicationController
  allow_unauthenticated_access only: %i[new create claim handle_claim verify]

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
      otp_token: otp_instance.token,
    ).ProPro_Invite.deliver_later

    redirect_back_or_to '/', notice: "Invitation resent to #{user.email_address}"
  end

  def new; end

  def create
    name = params[:name].strip
    email = params[:email].strip

    result = UserDetailsValidator.call(name: name, password: params[:password], password_confirmation: params[:password_confirmation])

    unless result.success?
      redirect_to user_new_path, alert: result.message
      return
    end

    result = UserCreator.call(name: name, email: email, password: params[:password], verify_only: true)

    unless result.success?
      redirect_back_or_to user_new_path, alert: result.message
      return
    end

    GeneralMailer.with(
      email_address: email,
      otp_token: result.otp_instance.token,
    ).Signup_Verification.deliver_later

    redirect_to login_path, notice: 'Account created successfully. Check your inbox!'
  end

  def edit
    @user = Current.user

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
    @email = Otp.find_by(token: params[:token], verify_only: false).user.email_address
  rescue StandardError
    redirect_to login_path, alert: "Invalid token, perhaps you've already claimed your account? Try logging in."
  end

  def handle_claim
    return if params[:token].blank?

    otp_instance = Otp.find_by(token: params[:token], verify_only: false)

    unless otp_instance
      redirect_back_or_to '/', alert: 'Something went wrong'
      return
    end

    user = otp_instance.user
    name = params[:name].strip

    result = UserDetailsValidator.call(name: name, password: params[:password], password_confirmation: params[:password_confirmation])

    if !result.success?
      redirect_back_or_to '/', alert: result.message
      return
    end

    begin
      user.update!(has_registered: true, name: name, password: params[:password])
      otp_instance.destroy
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_or_to '/', alert: e.message
      return
    rescue StandardError => e
      redirect_back_or_to '/', alert: 'Something went wrong'
      return
    end

    redirect_to '/session/new', notice: 'Account successfully claimed'
  end

  def verify
    return if params[:token].blank?

    otp_instance = Otp.find_by(token: params[:token], verify_only: true)

    unless otp_instance
      redirect_back_or_to new_session_path, alert: 'Something went wrong'
      return
    end

    user = otp_instance.user

    begin
      ActiveRecord::Base.transaction do
        user.update!(has_registered: true)
        otp_instance.destroy
      end
    rescue StandardError => e
      redirect_to new_session_path, alert: 'Something went wrong'
      return
    end

    redirect_to new_session_path, notice: 'Account successfully verified'
  end

  def profile
    @user = Current.user
  end
end
