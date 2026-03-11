require "test_helper"

class AttendeePortalControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(provider: "hackclub", uid: SecureRandom.hex)
    org  = Organisation.create!(user: user, signing_user: user, users: [ user ])
    @event = Event.create!(name: "Test", organisation: org, capacity: 1)
    @event.waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.txt")),
      filename: "sample.txt",
      content_type: "text/plain"
    )
    @attendee = Attendee.create!(name: "Foo", age: 20, event: @event)
    @attendee.reload
  end

  test "should get home when logged in" do
    get attendee_portal_path # unauthenticated redirects to login
    assert_redirected_to attendee_portal_login_path

    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!
    assert_response :success
  end

  test "waiver route requires login" do
    get attendee_portal_waiver_path
    assert_redirected_to attendee_portal_login_path

    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!
    get attendee_portal_waiver_path
    assert_response :success
  end

  test "signing waiver updates attendee" do
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    patch attendee_portal_waiver_path, params: {
      attendee: {
        waiver_signature: "Foo Bar",
        signed_waiver: fixture_file_upload(
          Rails.root.join("test/fixtures/files/sample.txt"),
          "text/plain"
        )
      }
    }
    assert_redirected_to attendee_portal_waiver_path
    @attendee.reload
    assert @attendee.waiver_signed?
    assert_equal "Foo Bar", @attendee.waiver_signature
    assert @attendee.signed_waiver.attached?
  end
end
