class PagesController < ApplicationController
  # Temporary: the landing-page showcase JS spike is public (root route) so it
  # can be checked logged-out. Remove with the rest of the spike.
  allow_unauthenticated_access only: %i[showcase_test]

  def showcase_test; end
end
