module SidebarHelper
  def render_sidebar(&)
    content_for :sidebar do
      safe_join([
                  # 1. THE BACKDROP (Mobile Overlay) — hidden by default, appears
                  #    when the sidebar drawer is open; click closes it.
                  tag.div(
                    class: 'hidden fixed inset-0 bg-black/30 z-40 lg:hidden',
                    data: {
                      sidebar_target: 'backdrop',
                      action: 'click->sidebar#close'
                    }
                  ),

                  # 2. THE SIDEBAR CONTAINER — off-canvas drawer below lg,
                  #    static sticky column at lg and up.
                  tag.div(
                    class: [
                      'w-[280px] bg-[#f8f9fa] border-r border-gray-200',
                      'overflow-x-hidden overflow-y-auto',
                      'fixed top-0 left-0 h-full z-50 -translate-x-full',
                      'transition-transform duration-300 ease-out',
                      'lg:static lg:translate-x-0 lg:transition-none lg:h-auto lg:shrink-0'
                    ],
                    data: { sidebar_target: 'container' }
                  ) do
                    # Inner Content Wrapper
                    tag.div(class: 'w-48 p-4 space-y-4 md:space-y-2 lg:space-y-1 pt-11 lg:pt-4 font-medium text-sm text-gray-600') do
                      capture(&)
                    end
                  end
                ])
    end
  end
end
