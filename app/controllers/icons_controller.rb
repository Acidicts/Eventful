class IconsController < ApplicationController
  skip_before_action :allow_browser, raise: false

  VALID_COLOR = /\A(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)\z/

  def menu_open
    raw = params[:color].presence || "black"
    @color = VALID_COLOR.match?(raw) ? raw : "black"
    expires_in 1.hour, public: true
    render "icons/menu_open", formats: [ :svg ], layout: false, content_type: "image/svg+xml"
  end
end
