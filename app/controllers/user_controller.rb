require 'net/http'
require 'uri'

class UserController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  def new
  end

  def create
    response = params.permit(:email_address, :password, :role, :username, :mmu_directory)
    
    if response[:email_address].blank?
      redirect_to user_new_path, alert: "Email cannot be empty."
      return
    end

    if User.find_by(email_address: response[:email_address].strip, has_registered: true)
      redirect_to user_new_path, alert: "Account already exists"
      return
    end

    if response[:password].blank?
      redirect_to user_new_path, alert: "Password cannot be empty."
      return
    end
    
    if response[:role].blank?
      redirect_to user_new_path, alert: "Role cannot be empty."
      return
    
    elsif response[:role] == "student"

      if ghost_account = User.find_by(email_address: response[:email_address].strip, has_registered: false, is_staff: false)
        ghost_account.update(has_registered: true, password: response[:password])
        redirect_to user_new_path, notice: "Account successfully claimed"
        return
      else
        redirect_to user_new_path, alert: "Your account needs to be imported into the system first. Please contact your lecturer."
        return
      end

    elsif response[:role] == "staff"
      =begin
      if response[:mmu_directory].blank?
        redirect_to user_new_path, alert: "MMU Directory cannot be blank"
        return
      elsif User.find_by(mmu_directory: response[:mmu_directory].strip)
        redirect_to user_new_path, alert: "MMU Directory has already been claimed by another user"
        return
      end
      =end
      if response[:username].blank?
        redirect_to user_new_path, alert: "Name cannot be empty"
        return
      end
      =begin
      uri = URI.parse("https://mmuexpert.mmu.edu.my/" + response[:mmu_directory].to_s.strip)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = 3

      request = Net::HTTP::Head.new(uri.request_uri)

      if http.request(request).code.to_i != 200
        redirect_to user_new_path, alert: "Invalid MMU Directory"
        return
      end
      =end
      if User.create(email_address: response[:email_address].strip, password: response[:password], username: response[:username].strip, has_registered: true, is_staff: true)
        redirect_to user_new_path, notice: "Account created successfully"
      else
        redirect_to user_new_path, alert: "Account creation failed"
      end
      
    end

  end

end
