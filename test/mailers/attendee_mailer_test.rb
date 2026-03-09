require "test_helper"

class AttendeeMailerTest < ActionMailer::TestCase
  include ActiveJob::TestHelper
  test "qr_code email contains attendee details and qr image" do
    # environment variables should configure SMTP; this ensures the
    # initializer read them correctly (development/test environments still
    # configure delivery_method=:smtp by default in our setup).
    assert_equal ENV["SMTP_ADDRESS"], ActionMailer::Base.smtp_settings[:address]
    # security flags should not both be true
    smtp = ActionMailer::Base.smtp_settings
    assert_not (smtp[:tls] && smtp[:enable_starttls_auto])
    # either tls or starttls should be set depending on port
    if ENV["SMTP_PORT"] == "465"
      assert smtp[:tls]
    else
      assert smtp[:enable_starttls_auto]
    end
    user = User.create!(name: "Owner", email: "owner@example.com", provider: "hackclub", uid: "u1")
    org  = Organisation.create!(user: user, signing_user: user, users: [ user ])
    event = org.events.create!(name: "Party", capacity: 5)

    attendee = event.attendees.create!(name: "Bob", email: "bob@example.com")

    email = AttendeeMailer.qr_code(attendee)

    assert_equal [ "bob@example.com" ], email.to
    assert_match(/Your QR code/, email.subject)

    # the generated body should include the URL the QR code encodes as well
    url = Rails.application.routes.url_helpers.attendee_organisation_event_url(
      attendee.event.organisation,
      attendee.event,
      attendee_id: attendee.id,
      host: "example.com"
    )
    assert_match url, email.body.encoded
    assert_match(/<img/, email.body.encoded)
    # since the image is attached, the body should reference a cid: URL
    assert_match(/cid:/, email.body.encoded)
    assert_equal 1, email.attachments.inline.size

    # the explicit QR page link should be present and use APP_URL
    qr_page = "#{ENV.fetch("APP_URL")}/qrcode/#{attendee.code}"
    assert_match qr_page, email.body.encoded
  end
end
