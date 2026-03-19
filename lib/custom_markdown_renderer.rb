# frozen_string_literal: true

require "redcarpet"
require "sanitize"

# Custom renderer that extends Redcarpet's HTML renderer
class CustomMarkdownRenderer < Redcarpet::Render::HTML
  # Example: Add a CSS class to all paragraphs
  def paragraph(text)
    "<p class='markdown-paragraph'>#{text}</p>"
  end

  # Example: Add target="_blank" to all links
  def link(link, title, content)
    title_attr = title ? " title='#{ERB::Util.html_escape(title)}'" : ""
    "<a href='#{ERB::Util.html_escape(link)}'#{title_attr} target='_blank' rel='noopener'>#{content}</a>"
  end

  # Support markdown image sizing via title metadata, e.g.
  # ![Diagram](/learn/assets/x.svg "w=720 h=320")
  def image(link, title, alt_text)
    safe_link = ERB::Util.html_escape(link.to_s)
    safe_alt = ERB::Util.html_escape(alt_text.to_s)
    meta = parse_image_meta(title)
    width_attr = meta[:width] ? " width='#{meta[:width]}'" : ""
    height_attr = meta[:height] ? " height='#{meta[:height]}'" : ""
    title_attr = meta[:title] ? " title='#{ERB::Util.html_escape(meta[:title])}'" : ""

    "<img class='markdown-image' src='#{safe_link}' alt='#{safe_alt}' loading='lazy'#{title_attr}#{width_attr}#{height_attr}>"
  end

  # Render GitHub-style task list items: "- [x] ..." and "- [ ] ...".
  # We output a span with a checkbox glyph so Sanitize::RELAXED won't strip it.
  def list_item(text, list_type)
    # Normalize possible surrounding <p> tags Redcarpet may produce
    inner = text.to_s.gsub(/\A\s*<p>\s*/m, "").gsub(/\s*<\/p>\s*\z/m, "")

    if inner =~ /\A\s*\[([ xX])\]\s*(.*)/m
      checked = Regexp.last_match(1).strip.downcase == "x"
      content = Regexp.last_match(2)
      state_class = checked ? "task-list-item--checked" : "task-list-item--unchecked"

      # Use SVG files when present, but gracefully fall back to text glyphs
      # when the assets are not available in the current pipeline/load path.
      unchecked_svg = nil
      checked_svg = nil
      if defined?(ActionController::Base) && ActionController::Base.respond_to?(:helpers)
        begin
          unchecked_svg = ERB::Util.html_escape(ActionController::Base.helpers.asset_path("empty_checkbox.svg"))
          checked_svg = ERB::Util.html_escape(ActionController::Base.helpers.asset_path("ticked_checkbox.svg"))
        rescue StandardError
          unchecked_svg = nil
          checked_svg = nil
        end
      end

      sr = checked ? " (checked)" : " (not checked)"
      icon_markup =
        if checked_svg && unchecked_svg
          img_src = checked ? checked_svg : unchecked_svg
          "<img class='task-list-item-pixel' src='#{img_src}' alt=''>"
        else
          fallback_glyph = checked ? "checkbox-checked" : "checkbox"
          fallback_src = ERB::Util.html_escape("https://icons.hackclub.com/api/icons/slate/#{fallback_glyph}")
          "<img class='task-list-item-pixel' src='#{fallback_src}' alt=''>"
        end

      "<li class='task-list-item #{state_class}'>" +
        "<span class='task-list-item-checkbox' aria-hidden='true'>" +
          icon_markup +
        "</span> " +
        "<span class='task-list-item-label'>#{content}<span class='sr-only'>#{sr}</span></span>" +
      "</li>"
    else
      "<li>#{text}</li>"
    end
  end

  private

  def parse_image_meta(raw_title)
    text = raw_title.to_s
    width = text[/\b(?:w|width)\s*=\s*(\d{1,4})\b/i, 1]
    height = text[/\b(?:h|height)\s*=\s*(\d{1,4})\b/i, 1]
    cleaned_title = text.gsub(/\b(?:w|width|h|height)\s*=\s*\d{1,4}\b/i, "").strip

    {
      width: width,
      height: height,
      title: cleaned_title.empty? ? nil : cleaned_title
    }
  end
end

# Helper method to convert Markdown to safe HTML
def markdown_to_html(markdown_text)
  return "" if markdown_text.nil? || markdown_text.strip.empty?

  renderer = CustomMarkdownRenderer.new(
    filter_html: true, # Prevent raw HTML injection
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

  # Convert and sanitize output to prevent XSS
  Sanitize.fragment(
    markdown.render(markdown_text),
    Sanitize::Config::RELAXED
  )
end
