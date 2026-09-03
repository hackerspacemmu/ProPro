module BreadcrumbHelper
  GOOGLE_SANS_FONT = 'Google Sans,Roboto,Arial,sans-serif'

  def current_breadcrumb_page_name
    return '' unless breadcrumbs.present? && breadcrumbs.any?

    breadcrumbs.last.text
  end

  def render_custom_breadcrumbs
    return unless breadcrumbs.present? && breadcrumbs.any?

    content_for(:breadcrumbs) do
      tag.nav(class: 'flex flex-wrap items-center text-gray-500 w-full min-w-0') do
        elements = breadcrumbs.drop(1).map.with_index do |crumb, index|
          chunk = [breadcrumb_chevron]
          chunk << breadcrumb_crumb(crumb, last: index == breadcrumbs.drop(1).count - 1)
          safe_join(chunk)
        end

        safe_join(elements)
      end
    end
  end

  private

  def breadcrumb_crumb(crumb, last:)
    if last
      tag.span(crumb.text,
               class: 'text-gray-900 font-medium text-[1rem] leading-6 break-all',
               style: "font-family: #{GOOGLE_SANS_FONT}")
    else
      link_to crumb.text, crumb.url,
              class: [
                'whitespace-nowrap',
                'text-[1rem] leading-6',
                'font-medium',
                'text-[#5F6368]',
                'hover:text-[#3C4043]',
                'transition-colors',
                'no-underline'
              ].join(' '),
              style: "font-family: #{GOOGLE_SANS_FONT}"
    end
  end

  def breadcrumb_chevron
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="1.25rem" height="1.25rem" fill="currentColor" class="mx-2 shrink-0 select-none text-[#9AA0A6]" aria-hidden="true"><path d="M9.29 6.71a.996.996 0 0 0 0 1.41L13.17 12l-3.88 3.88a.996.996 0 1 0 1.41 1.41l4.59-4.59a.996.996 0 0 0 0-1.41L10.7 6.7a.996.996 0 0 0-1.41 0z"/></svg>
    SVG
  end
end
