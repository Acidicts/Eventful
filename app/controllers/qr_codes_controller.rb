# frozen_string_literal: true

class QrCodesController < ApplicationController
  # form for entering text to generate a QR code
  def new
    @data = params[:data]
    @qr_image = QrCodeGenerator.generate(@data) if @data.present?
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
end
