# Public landing page served at root. Only reachable without authentication;
# signed-in visitors bounce straight to the dashboard.
class LandingController < ApplicationController
  allow_unauthenticated_access only: %i[show]

  def show
    redirect_to dashboard_path if authenticated?
  end
end
