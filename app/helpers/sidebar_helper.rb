module SidebarHelper
  def render_sidebar(&)
    content_for :sidebar do
      # 1. Wrapper div (relative)
      safe_join([
                  # 2. THE BACKDROP (Mobile Overlay)
                  # Hidden by default, appears when sidebar is open on mobile.
                  # Clicking it triggers the 'collapse' action in the controller.
                  tag.div(
                    class: 'fixed inset-0 bg-gray-900/50 z-30 transition-opacity duration-300 opacity-0 pointer-events-none lg:hidden',
                    data: {
                      sidebar_target: 'backdrop',
                      action: 'click->sidebar#collapse'
                    }
                  ),

                  # 3. THE SIDEBAR CONTAINER
                  tag.div(
                    class: [
                      # --- Mobile Styles (Modal/Drawer) ---
                      'fixed inset-y-0 left-0 z-40 h-full', # Fixed height, covers top-to-bottom
                      'shadow-xl', # Shadow for "floating" effect

                      # --- Desktop Styles (Sticky Sidebar) ---
                      'lg:sticky lg:top-[70px] lg:h-[calc(100vh-70px)] lg:z-20',
                      'lg:shadow-none',

                      # --- Shared Styles ---
                      'bg-[#f8f9fa] border-r border-gray-200',
                      'overflow-x-hidden overflow-y-auto',
                      'transition-all duration-300 ease-in-out',

                      # --- Initial State ---
                      'w-0 opacity-0',           # Hidden on mobile start
                      'lg:w-64 lg:opacity-100'   # Visible on desktop start
                    ],
                    data: { sidebar_target: 'container' }
                  ) do
                    # Inner Content Wrapper
                    tag.div(class: 'w-64 p-4 space-y-4 md:space-y-2 lg:space-y-1 pt-11 lg:pt-4 font-medium text-sm text-gray-600') do
                      capture(&)
                    end
                  end
                ])
    end
  end

  def sidebar_link(label, path)
    link_to(
      label,
      path,
      class: 'block p-0 md:p-1 lg:px-2 lg:py-1.75 w-full rounded-md hover:bg-gray-200 hover:text-gray-900 transition-colors'
    )
  end
end
