class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :staff?, :student?
  
  def staff?
    current_user&.is_staff == true
  end

  def student?
    current_user&.is_staff == false
  end
end
