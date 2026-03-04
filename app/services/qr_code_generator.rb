# frozen_string_literal: true

# Service object responsible for generating QR codes from arbitrary text.
# Uses the rqrcode gem to create SVG or PNG data that can be embedded in views.
#
# Example:
#   svg = QrCodeGenerator.generate("hello world")
#   png = QrCodeGenerator.generate("hello world", format: :png)
class QrCodeGenerator
  require "rqrcode"

  # Generate a QR code for the provided `data` string.
  #
  # @param data [String] the alphanumeric data to encode
  # @param options [Hash] options that control output formatting:
  #   * :format - :svg (default) or :png
  #   * :size   - module size when rendering (default 6 for SVG, 200 for PNG)
  #   * any other options are forwarded to the underlying rqrcode renderer
  #
  # @return [String] an SVG/PNG encoded as plain text (SVG) or a Base64 data URI (PNG)
  def self.generate(data, options = {})
    raise ArgumentError, "data must be a String" unless data.is_a?(String)

    qrcode = RQRCode::QRCode.new(data)

    format = options.fetch(:format, :svg).to_sym
    case format
    when :svg
      qrcode.as_svg(
        offset: 0,
        color: "000",
        shape_rendering: "crispEdges",
        module_size: options.fetch(:size, 6)
      )
    when :png
      png = qrcode.as_png(size: options.fetch(:size, 200))
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    else
      raise ArgumentError, "unsupported format: #{format}"
    end
  end
end
