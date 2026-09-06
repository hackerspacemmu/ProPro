module ApplicationHelper
  # Resolves which content tab is active on load for the pages that persist the
  # active tab in a per-resource cookie (courses/show, projects/show, topics/show).
  #
  # The cookie is deliberately plain/unsigned — and only ever read through the
  # `slugs` allowlist — so a forged value can at most land the user on the
  # default (index 0) tab. Defaults to index 0 whenever the cookie is absent or
  # doesn't name one of the given slugs.
  def current_tab_index(persist_key:, slugs:)
    slugs.index(cookies[persist_key]) || 0
  end

  # Server-side read of the sidebar rail-collapse preference, mirroring
  # current_tab_index: plain/unsigned cookie because the value is written
  # client-side by sidebar_controller.js (the same cookie convention
  # tabs_controller.js uses). Only "true" means collapsed; anything else
  # (absent, forged, "false") means expanded.
  def sidebar_collapsed?
    cookies[:propro_sidebar_rail_collapsed] == 'true'
  end

  def format_timestamp(datetime)
    return '-' if datetime.blank?

    datetime.strftime('%I:%M %p, %d %b %Y')
  end

  def status_badge_classes(status)
    case status
    when 'pending'  then 'bg-sky-700'
    when 'redo'     then 'bg-amber-600'
    when 'rejected' then 'bg-red-700'
    when 'approved' then 'bg-emerald-600'
    else 'bg-gray-600'
    end
  end
end
