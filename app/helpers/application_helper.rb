module ApplicationHelper
  # Server-side read of the sidebar rail-collapse preference: plain/unsigned
  # cookie because it is written client-side by sidebar_controller.js. Only
  # "true" means collapsed; anything else (absent, forged, "false") means
  # expanded.
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
