class UserController < ApplicationController
  allow_unauthenticated_access only: %i[ new_staff new_student create ]
  def new_student
  end

  def new_staff
  end

  def create
    # mmu_directory validation code
     #if response[:mmu_directory].blank?
     #  redirect_to user_new_path, alert: "MMU Directory cannot be blank"
     #  return
     #elsif User.find_by(mmu_directory: response[:mmu_directory].strip)
     #  redirect_to user_new_path, alert: "MMU Directory has already been claimed by another user"
     #  return
     #end
     
     #uri = URI.parse("https://mmuexpert.mmu.edu.my/" + response[:mmu_directory].to_s.strip)
     #
     #http = Net::HTTP.new(uri.host, uri.port)
     #http.use_ssl = (uri.scheme == "https")
     #http.read_timeout = 3

     #request = Net::HTTP::Head.new(uri.request_uri)

     #if http.request(request).code.to_i != 200
     #  redirect_to user_new_path, alert: "Invalid MMU Directory"
     #  return
     #end

    response = params.permit(:password, :username, :token, :otp)
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
    elsif response[:password].length > 72
      redirect_back_or_to "/", alert: "Password too long"
      return
    end

    otp_instance = Otp.find_by(token: response[:token], otp: response[:otp])

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

    begin
      Current.user.update!(
        username: params[:user][:username],
        web_link: params[:user][:web_link],
        description: params[:user][:description]
        )
    rescue StandardError => e
      render :profile, status: :unprocessable_entity
      return
    end

    redirect_back_or_to "/", notice: "Profile updated successfully"
  end
end

