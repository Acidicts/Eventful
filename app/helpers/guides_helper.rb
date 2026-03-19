module GuidesHelper
  def render_guide_markdown(content)
    return "".html_safe if content.blank?

    renderer = CustomMarkdownRenderer.new(
      filter_html: true,
      hard_wrap: true
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      underline: true
    )

    Sanitize.fragment(markdown.render(content), Sanitize::Config::RELAXED).html_safe
  end
end
