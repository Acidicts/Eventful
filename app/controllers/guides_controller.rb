class GuidesController < ApplicationController
  layout "guides"

  GUIDE_SLUGS = {
    index: "getting_started",
    getting_started: "getting_started",
    organisations: "organisations",
    events: "events",
    attendees: "attendees",
    faqs: "faqs"
  }.freeze

  MARKDOWN_ROOT = Rails.root.join("public", "guides", "markdown").freeze
  IMAGE_ROOT = Rails.root.join("public", "guides", "images").freeze

  def index
    render_guide(:index)
  end

  def getting_started
    render_guide(:getting_started)
  end

  def organisations
    render_guide(:organisations)
  end

  def events
    render_guide(:events)
  end

  def attendees
    render_guide(:attendees)
  end

  def faqs
    render_guide(:faqs)
  end

  def doc
    guide_path = sanitize_markdown_path(params[:path])
    return head :not_found if guide_path.blank?

    markdown_file = MARKDOWN_ROOT.join("#{guide_path}.md")
    return head :not_found unless safe_path?(markdown_file, MARKDOWN_ROOT) && markdown_file.file?

    @current_guide = guide_path
    @content = markdown_file.read
    load_guide_tree
    render :index
  end

  def asset
    clean_path = sanitize_asset_path(params[:path])
    return head :not_found if clean_path.blank?

    asset_file = IMAGE_ROOT.join(clean_path)
    return head :not_found unless safe_path?(asset_file, IMAGE_ROOT) && asset_file.file?

    send_file asset_file, disposition: "inline", type: Rack::Mime.mime_type(asset_file.extname, "application/octet-stream")
  end

  private

  def render_guide(action_key)
    slug = GUIDE_SLUGS.fetch(action_key)
    markdown_file = MARKDOWN_ROOT.join("#{slug}.md")

    return head :not_found unless safe_path?(markdown_file, MARKDOWN_ROOT) && markdown_file.file?

    @current_guide = slug
    @content = markdown_file.read
    @page_title = slug.tr("_-", " ").split.map(&:capitalize).join(" ")
    load_guide_tree
    render :index
  end

  def load_guide_tree
    @guide_tree = Hash.new { |hash, key| hash[key] = [] }

    Dir.glob(MARKDOWN_ROOT.join("**", "*.md")).sort.each do |absolute_path|
      path = Pathname.new(absolute_path)
      next unless safe_path?(path, MARKDOWN_ROOT)

      relative = path.relative_path_from(MARKDOWN_ROOT).to_s
      slug = relative.sub(/\.md\z/, "")
      folder = File.dirname(relative)
      folder = "root" if folder == "."
      filename = File.basename(relative, ".md")
      title = filename.tr("_-", " ").split.map(&:capitalize).join(" ")

      @guide_tree[folder] << { title: title, slug: slug }
    end
  end

  def sanitize_markdown_path(raw_path)
    path = raw_path.to_s.strip
    return nil if path.blank?
    return nil if path.include?("\0")

    clean = Pathname.new(path).cleanpath.to_s
    return nil if clean == "." || clean.start_with?("/")

    clean
  end

  def sanitize_asset_path(raw_path)
    path = raw_path.to_s.strip
    return nil if path.blank?
    return nil if path.include?("\0")

    Pathname.new(path).cleanpath.to_s
  end

  def safe_path?(candidate, root)
    expanded_candidate = candidate.expand_path.to_s
    expanded_root = root.expand_path.to_s

    expanded_candidate == expanded_root || expanded_candidate.start_with?("#{expanded_root}/")
  end
end
