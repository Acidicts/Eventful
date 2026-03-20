# frozen_string_literal: true

class QrCodesController < ApplicationController
  before_action :require_login, except: %i[show]
  before_action -> { require_permission!("qr-code-generate", fallback: root_path, organisation: nil) }, only: %i[new create login_phone_demo]
  before_action -> { require_permission!("qr-code-decode", fallback: root_path, organisation: nil) }, only: %i[decode]
  before_action -> { require_permission!("qr-code-public-view", fallback: root_path, organisation: nil) }, only: %i[show], if: -> { logged_in? }

  # form for entering text to generate a QR code
  def new
    @data = params[:data]
    @qr_image = QrCodeGenerator.generate(@data) if @data.present?
  end

  def login_phone_demo
    @qr_svg = QrCodeGenerator.generate(ENV.fetch("APP_URL"))
  end

  # POST action used by the form. we simply redirect back to new with the
  # entered data so that the generated code can be displayed.
  def create
    data = params.require(:data)
    redirect_to new_qr_code_path(data: data)
  end

  # page that opens the device camera and decodes a QR code via javascript
  def decode
    # nothing to prepare server-side; decoding is handled in the client
  end

  # GET /qrcode/:code
  def show
    # look up attendee by their unique code – if nothing is found we want a
    # friendly message rather than a hard error, because scanners may point at
    # expired or mistyped codes.
    @attendee = Attendee.find_by(code: params[:code])

    unless @attendee
      # render a minimal error page (could be styled or localized) and skip
      # application layout so it's easy to embed or print.
      @error_message = "Attendee not found for code #{params[:code]}"
      render "show_not_found", layout: false, status: :not_found and return
    end

    @event = @attendee.event
    @organisation = @event.organisation

    # render a simple QR image containing the attendee’s unique code
    # (not the full link) so that scanners yield the raw code string.
    @qr_svg = QrCodeGenerator.generate(@attendee.code)

    # this page is often embedded in other systems or printed; keep it
    # bare-bones by skipping the application layout entirely.
    render layout: false
  end
end
