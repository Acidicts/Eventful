require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    user = User.create!(provider: "test", uid: SecureRandom.uuid, role: "member")
    organisation = Organisation.create!(user: user, signing_user: user, users: [ user ])
    @event = organisation.events.create!(name: "Test Event", description: "desc")
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

  test "can attach a small icon image" do
    @event.icon.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    assert @event.icon.attached?
    assert_equal "sample.png", @event.icon.filename.to_s
  end

  test "rejects invalid icon type" do
    @event.icon.attach(
      io: StringIO.new("not image"),
      filename: "not.txt",
      content_type: "text/plain"
    )

    refute @event.valid?
    assert_includes @event.errors[:icon], "must be a PNG, JPEG or GIF image"
  end

  test "rejects too-large icon" do
    @event.icon.attach(
      io: StringIO.new("x" * 3.megabytes),
      filename: "big.png",
      content_type: "image/png"
    )

    refute @event.valid?
    assert_includes @event.errors[:icon], "cannot be larger than 2 MB"
  end
end
