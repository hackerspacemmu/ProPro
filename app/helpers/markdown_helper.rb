module MarkdownHelper
  def render_markdown(text)
    return '' if text.blank?

    options = {
      filter_html: true,
      safe_links_only: true,
      hard_wrap: true,
      link_atributes: { target: '_blank', rel: 'noopener noreferrer' }
    }

    renderer = Redcarpet::Render::HTML.new(options)

    extensions = {
      autolink: true,
      tables: true,
      space_after_headers: true,
      fenced_code_blocks: true,
      superscript: true,
      strikethrough: true
    }

    markdown = Redcarpet::Markdown.new(renderer, extensions)
    markdown.render(text).html_safe
  end

  def plaintext_markdown_preview(markdown_text, length: 200)
    html = render_markdown(markdown_text)
    text = strip_tags(html)
    text = text.gsub(/^[#>\-\*\+]+\s+/, '')
               .gsub(/[*_~`]/, '')
               .strip
    truncated_text = truncate(text, length: length)

    truncated_text.gsub("\n", '<br>').html_safe
  end
end
