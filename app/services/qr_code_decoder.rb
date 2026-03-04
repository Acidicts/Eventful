# frozen_string_literal: true

# Simple wrapper around the zxing gem to decode QR codes from image data.
# The service is optional because client‑side decoding (via javascript) is
# used when scanning with a phone camera, but this class provides a convenient
# server-side fallback for uploaded images or API endpoints.
#
# Example:
#   QrCodeDecoder.decode_file(path_to_png)
#   QrCodeDecoder.decode_blob(binary_image)
class QrCodeDecoder
  # note: zxing is only required when a decode method is called, because the
  # gem attempts to start a java DRb process on require and that fails in
  # environments without java installed.

  class << self
    # Decode a file from disk.
    # @param path [String] file path
    # @return [String, nil] the decoded text or nil if nothing was found
    def decode_file(path)
      require_zxing
      ZXing.decode path
    end

    # Decode raw data (string or IO). Writes to a Tempfile before passing to
    # zxing since the underlying library expects a filename.
    # @param blob [String,IO] binary image data
    # @return [String, nil]
    def decode_blob(blob)
      require_zxing
      Tempfile.open([ "qr", ".png" ]) do |f|
        if blob.respond_to?(:read)
          f.write(blob.read)
        else
          f.write(blob)
        end
        f.rewind
        ZXing.decode(f.path)
      end
    end

    private

    def require_zxing
      require "zxing"
    rescue LoadError => e
      raise "ZXing gem not available (ensure java is installed): \\#{e.message}"
    end
  end
end
