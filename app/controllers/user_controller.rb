class UserController < ApplicationController
  allow_unauthenticated_access only: %i[ new_staff new_student create ]

  def resend_invite
    user = User.find(params[:id])
    if user.has_registered
      redirect_back_or_to "/", alert: "User already registered"
      return
    end
    
    # Ensure OTP exists or recreate if missing (though it should exist for unregistered users)
    otp_instance = user.otp || Otp.create!(user: user, otp: SecureRandom.base64(8), token: SecureRandom.uuid)
    
    GeneralMailer.with(
      email_address: user.email_address,
      otp_token: otp_instance.token,
      otp: otp_instance.otp,
      is_staff: user.is_staff
    ).ProPro_Invite.deliver_later

    redirect_back_or_to "/", notice: "Invitation resent to #{user.email_address}"
  end
  def new_student
    begin
      @email = Otp.find_by(token: params[:token]).user.email_address
    rescue StandardError
      redirect_to login_path, alert: "Invalid token, perhaps you've already claimed your account? Try logging in." 
    end
  end

  def new_staff
    begin
      @email = Otp.find_by(token: params[:token]).user.email_address
    rescue StandardError
      redirect_to login_path, alert: "Invalid token, perhaps you've already claimed your account? Try logging in."
    end
  end

  def create
    response = params.permit(:password, :password_confirmation, :username, :token, :otp)
    if response[:token].blank?
      return
    end

    if response[:otp].blank?
      redirect_back_or_to "/", alert: "OTP cannot be empty"
      return
    end

    if response[:password].blank?
      redirect_back_or_to "/", alert: "Password cannot be empty"
      return
    end

    if response[:password_confirmation].blank?
      redirect_back_or_to "/", alert: "Password confirmation cannot be empty"
      return
    end

    if response[:password] != response[:password_confirmation]
      redirect_back_or_to "/", alert: "Passwords are not the same"
      return
    end

    if response[:password].length > 72
      redirect_back_or_to "/", alert: "Password must be less than 72 characters"
      return
    end

    otp_instance = Otp.find_by(token: response[:token], otp: response[:otp].strip())

    if !otp_instance
      redirect_back_or_to "/", alert: "Something went wrong"
      return
    end

    user = otp_instance.user

    if response[:username].blank? && user.is_staff
      redirect_back_or_to "/", alert: "Name cannot be empty"
      return
    end
    
    # ugly ik, whachu gonna do about it
    if !user.is_staff
      if user.update(has_registered: true, password: response[:password])
        redirect_to "/session/new", alert: "Account successfully claimed"
      else
        redirect_back_or_to "/", alert: "Something went wrong"
      end
    else
      if user.update(has_registered: true, password: response[:password], username: response[:username].strip)
        redirect_to "/session/new", alert: "Account successfully claimed"
      else
        redirect_back_or_to "/", alert: "Something went wrong"
      end
    end

    user.otp.destroy
  end

  def profile
    @user = Current.user
  end

  def edit
    if !Current.user.is_staff
      redirect_back_or_to "/", alert: "Only staff can edit profiles"
      return
    end

    if params[:user][:username].blank?
      redirect_back_or_to "/", alert: "Username cannot be empty"
      return
    end

    if !params[:user][:new_password].blank?
      if params[:user][:new_password_confirmation].blank? or params[:user][:new_password] != params[:user][:new_password_confirmation]
        redirect_back_or_to "/", alert: "New passwords do not match"
        return
      elsif params[:user][:new_password].length > 72
        redirect_back_or_to "/", alert: "Password must be less than 72 characters"
        return
      end
    end

    begin
      Current.user.update!(
        username: params[:user][:username],
        web_link: params[:user][:web_link],
        description: params[:user][:description]
        )

      if !params[:user][:new_password].blank?
        Current.user.update!(password: params[:user][:new_password])
      end
    rescue StandardError => e
      render :profile, status: :unprocessable_entity
      return
    end

    redirect_to user_profile_path, notice: "Profile updated successfully"
  end
end

