class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_url, alert: "Try again later." }

  def new
  end

  def create
    response = params.permit(:email_address)

    user = User.find_by(email_address: response[:email_address])

    if user && !user.has_registered
      redirect_back_or_to "/", alert: "Please claim your account first"
      return
    end

    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to login_path, alert: "Invalid email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to login_path
  end
end
