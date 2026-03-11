require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @event = events(:one)
  end

  test "can attach a plaintext waiver" do
    @event.waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.txt")),
      filename: "sample.txt",
      content_type: "text/plain"
    )

    assert @event.waiver.attached?
    assert_equal "sample.txt", @event.waiver.filename.to_s
  end

  test "can attach a pdf waiver" do
    @event.waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.pdf")),
      filename: "sample.pdf",
      content_type: "application/pdf"
    )

    assert @event.waiver.attached?
  end

  test "rejects non‑text/pdf content types" do
    @event.waiver.attach(
      io: StringIO.new("not allowed"),
      filename: "bad.png",
      content_type: "image/png"
    )

    refute @event.valid?
    assert_includes @event.errors[:waiver], "must be a PDF or TXT file"
  end
end
