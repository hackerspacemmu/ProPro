require 'net/http'
require 'uri'
require 'securerandom'

class UserController < ApplicationController
  allow_unauthenticated_access only: %i[ new_staff new_student create create_otp get_otp]
  def new_student
  end
  
  def new_staff
  end
  
  def get_otp
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

    response = params.permit(:password, :username, :otp)
    
    if response[:password].blank?
      redirect_back_or_to "/", alert: "Password cannot be empty"
      return
    end

    if response[:otp].blank?
      redirect_back_or_to "/", alert: "OTP cannot be empty"
      return
    end

    otp_instance = Otp.find_by(otp: response[:otp])

    if !otp_instance
      redirect_back_or_to "/", alert: "Invalid OTP"
      return
    end

    user_email = otp_instance.email_address
    otp_instance.destroy
    
    # we've rejected emails from other domains so it's possible to assume that any email that doesn't have 'student' is staff
    if user_email.include? "@student.mmu.edu.my"
      staff = false
    else
      staff = true
    end

    if response[:username].blank? && staff
      redirect_back_or_to "/", alert: "Name cannot be empty"
      return
    end
    
    if ghost_account = User.find_by(email_address: user_email, has_registered: false)
      if !staff
        ghost_account.update(has_registered: true, password: response[:password])
      else
        ghost_account.update(has_registered: true, password: response[:password], username: response[:username].strip)
      end

      redirect_back_or_to "/", notice: "Account successfully claimed"
      return
    elsif staff
      if User.create(email_address: user_email, password: response[:password], username: response[:username].strip, has_registered: true, is_staff: true)
        redirect_to user_new_path, notice: "Account created successfully"
        return
      else
        redirect_to user_new_path, alert: "Account creation failed"
        return
      end
    end
  end

  def create_otp
    user_email = params[:email_address].strip

    if user_email.blank?
      redirect_to user_get_otp_path, alert: "Email cannot be blank"
      return
    elsif User.find_by(email_address: user_email, has_registered: true)
      redirect_to user_get_otp_path, alert: "Account already exists"
      return
    elsif user_email.include? "@student.mmu.edu.my"
      if !User.exists?(email_address: user_email, has_registered: false, is_staff: false)
        redirect_to user_get_otp_path, alert: "Your account needs to be imported into the system first. Please contact your lecturer."
        return
      end
      staff = false
    elsif user_email.include? "@mmu.edu.my"
      staff = true
    else
      redirect_to user_get_otp_path, alert: "Please use an MMU email"
      return
    end

    random_otp = SecureRandom.base64(8)

    if existing_otp_instance = Otp.find_by(email_address: user_email)
      existing_otp_instance.update(otp: random_otp)
    else
      Otp.create(email_address: user_email, otp: random_otp)
    end

    GeneralMailer.with(email_address: params[:email_address].strip).send_otp.deliver_now
    
    if staff
      redirect_to user_new_staff_path
    else
      redirect_to user_new_student_path
    end
  end
end

