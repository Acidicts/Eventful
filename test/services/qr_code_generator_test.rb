require "test_helper"

class QrCodeGeneratorTest < ActiveSupport::TestCase
  test "generate returns svg string for simple input" do
    svg = QrCodeGenerator.generate("HELLO123")
    assert_match(/<svg/, svg)
    # generated QR codes use <rect> elements for modules, not <path>
    assert_match(/<rect/, svg)
  end

  test "supports png format" do
    data_uri = QrCodeGenerator.generate("foo", format: :png)
    assert_match(%r{data:image/png;base64,}, data_uri)
  end

  test "rejects non-string data" do
    assert_raises(ArgumentError) { QrCodeGenerator.generate(123) }
  end
end
