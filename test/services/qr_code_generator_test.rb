require "test_helper"

class QrCodeGeneratorTest < ActiveSupport::TestCase
  test "generate returns svg string for simple input" do
    svg = QrCodeGenerator.generate("HELLO123")
    assert_match(/<svg/, svg)
    # generated QR codes use <rect> elements for modules, not <path>
    assert_match(/<rect/, svg)

    # ensure output is ready for inline use
    assert_no_match(/<\?xml/, svg, "xml declaration should be stripped")
    assert_match(/viewBox="0 0 \d+ \d+"/, svg, "svg must include viewBox for scaling")

    # viewBox dimensions should be larger than a trivial 0‑0 box; this guards
    # against miscomputed values like the erroneous 50×50 seen previously.
    viewbox = svg[/viewBox="([^"]+)"/, 1]
    w, h = viewbox.split.map(&:to_i)[2, 2]
    assert_operator w, :>, 50
    assert_operator h, :>, 50
  end

  test "supports png format" do
    data_uri = QrCodeGenerator.generate("foo", format: :png)
    assert_match(%r{data:image/png;base64,}, data_uri)
  end

  test "rejects non-string data" do
    assert_raises(ArgumentError) { QrCodeGenerator.generate(123) }
  end
end
