require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess

  setup do
    OmniAuth.config.test_mode = true
    uid = SecureRandom.hex
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: uid,
      info: {
        name: "Controller Test User",
        email: "controller-test-#{uid}@example.com",
        admin: false
      },
      credentials: {
        token: "tok",
        refresh_token: "ref",
        expires_at: 1.day.from_now.to_i
      }
    )

    user = User.create!(provider: "hackclub", uid: uid, email: "controller-test-#{uid}@example.com")

    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!

    @organisation = Organisation.create!(user: user, signing_user: user, users: [ user ])
    @event = Event.create!(name: "Sample", organisation: @organisation, capacity: 5)
  end

  teardown do
    OmniAuth.config.test_mode = false
  end
  test "should update event with waiver" do
    patch organisation_event_path(@organisation, @event), params: {
      event: {
        name: "Updated name",
        waiver: fixture_file_upload(
          Rails.root.join("test/fixtures/files/sample.txt"),
          "text/plain"
        )
      }
    }
    assert_redirected_to organisation_event_path(@organisation, @event)
    @event.reload
    assert_equal "Updated name", @event.name
    assert @event.waiver.attached?
  end

  test "attendee waiver page shows details" do
    attendee = Attendee.create!(name: "Joe", age: 20, event: @event)
    get attendee_waiver_organisation_event_path(@organisation, @event, attendee_id: attendee.id)
    assert_response :success
    assert_select "h1", /Attendee waiver/
  end


  test "can delete attendee waiver via dashboard" do
    attendee = Attendee.create!(name: "Joe", age: 20, event: @event)
    attendee.signed_waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.txt")),
      filename: "sample.txt",
      content_type: "text/plain"
    )

    delete destroy_attendee_waiver_organisation_event_path(@organisation, @event, attendee_id: attendee.id)
    assert_redirected_to attendee_waiver_organisation_event_path(@organisation, @event, attendee_id: attendee.id)
    attendee.reload
    refute attendee.signed_waiver.attached?
  end
end
