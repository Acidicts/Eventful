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
      svg = qrcode.as_svg(
        offset: 0,
        color: "000",
        shape_rendering: "crispEdges",
        module_size: options.fetch(:size, 6)
      )

      # remove optional XML declaration that RQRCode prepends; browsers
      # already treat the string as markup, and leaving it can break inline
      # rendering when we insert the SVG into a larger document.
      svg.sub!(/\A<\?xml[^>]*\?>\s*/i, "")

      # ensure the SVG carries a viewBox so that it can scale responsively.
      unless svg =~ /viewBox=/
        # try to infer dimensions from explicit width/height attributes first;
        # if those are wrong (as in the user-provided example) fall back to
        # calculating bounds by scanning module <rect> elements.
        if svg =~ /<svg[^>]+width="(\d+)"[^>]+height="(\d+)"/i
          w, h = $1.to_i, $2.to_i
        else
          # scan for the maximum x/y position among modules
          module_size = options.fetch(:size, 6).to_i
          xs = svg.scan(/x="(\d+)"/).flatten.map(&:to_i)
          ys = svg.scan(/y="(\d+)"/).flatten.map(&:to_i)
          if xs.any? && ys.any?
            w = xs.max + module_size
            h = ys.max + module_size
          end
        end

        if w && h
          svg.sub!("<svg", "<svg viewBox=\"0 0 #{w} #{h}\"")
        end
      end

      svg
    when :png
      png = qrcode.as_png(size: options.fetch(:size, 200))
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    else
      raise ArgumentError, "unsupported format: #{format}"
    end
  end
end
