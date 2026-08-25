module MarkdownHelper
  def render_markdown(text)
    return '' if text.blank?

    html = Commonmarker.to_html(
      text,
      options: {
        extension: {
          table: true,
          strikethrough: true,
          autolink: true,
          superscript: true
        },
        render: {
          unsafe: false,
          hardbreaks: true
        }
      }
    )

    add_link_attributes(html).html_safe
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

  private

  # Use nokogiri to replicate link_attributes target/rel injection
  def add_link_attributes(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('a').each do |link|
      link['target'] = '_blank'
      link['rel'] = 'noopener noreferrer'
    end
    doc.to_html
  end
end