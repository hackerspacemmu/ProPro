class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

def user_not_authorized
  redirect_to root_path, alert: "You are not authorized to view this page."
end
end
