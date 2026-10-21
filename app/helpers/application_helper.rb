# View helpers shared by every page: content-tab persistence and the
# resizable comments panel.
module ApplicationHelper
  # Width bounds for the resizable comments panel (#comments-drawer). Mirrored
  # in app/javascript/controllers/comments_panel_controller.js: the server
  # clamp, the client clamp and the CSS min-width all enforce the same range.
  COMMENTS_PANEL_MIN_WIDTH = 320
  COMMENTS_PANEL_MAX_WIDTH = 560
  COMMENTS_PANEL_DEFAULT_WIDTH = 360

  # Resolves which content tab is active on load for the pages that persist the
  # active tab in a per-resource cookie (projects/show, topics/show — the course
  # tabs dropped their cookie when they became routes).
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

  # Server-side read of the comments panel width, mirroring sidebar_collapsed?:
  # the value is written client-side by comments_panel_controller.js (the same
  # plain/unsigned cookie convention tabs_controller.js and
  # sidebar_controller.js use). The client value is never trusted - it has to
  # be a whole number, and one outside the 320..560 range is clamped to it (the
  # same clamp the controller applies), while anything missing or non-numeric
  # falls back to the 360px default. Reading it here is what lets the drawer
  # render at its saved width on the first paint, so there is no flash and the
  # width survives the full-page redirect that follows posting a comment.
  def comments_panel_width
    raw = cookies[:propro_comments_panel_width].to_s
    return COMMENTS_PANEL_DEFAULT_WIDTH unless raw.match?(/\A\d+\z/)

    raw.to_i.clamp(COMMENTS_PANEL_MIN_WIDTH, COMMENTS_PANEL_MAX_WIDTH)
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

  # Whether the Progress Updates tab is shown on a project/topic show page.
  # Single canonical definition shared by every view (lives here rather than
  # duplicated across ProjectsHelper/TopicsHelper). Arguments are explicit so
  # helpers stay decoupled from controller ivars.
  def show_progress_tab?(course:, current_instance:)
    course.use_progress_updates && current_instance.status == 'approved'
  end
end
