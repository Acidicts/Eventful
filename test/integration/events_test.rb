require "test_helper"

class EventsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: "int123",
      info: {
        name: "Test User",
        email: "test@example.com",
        slack_id: "U123",
        verification_status: "verified",
        admin: false
      },
      credentials: {
        token: "tok",
        refresh_token: "ref",
        expires_at: 1.day.from_now.to_i
      }
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
  end

  # provide a sane user agent so the allow_browser filter doesn't block us
  def headers
    {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0 Safari/537.36",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }
  end

  # The top-level /events route has been removed in favor of org-scoped
  # URLs. hitting the former path should raise a routing error, which the
  # integration test framework simulates by raising ActionController::RoutingError.
  test "top-level events helpers are gone" do
    assert_raises(NameError) { events_path }
    # hitting the literal URL should return 404 since the route is gone
    get "/events", headers: headers
    assert_response :not_found
  end

  test "nested events index still works" do
    user = User.create!(name: "Foo", email: "foo@example.com", provider: "hackclub", uid: "u1")
    org  = Organisation.create!(user: user, signing_user: user, users: [ user ])

    get organisation_events_path(org), headers: headers
    assert_response :success
  end

  test "dashboard attendees page lists all organisation attendees" do
    # sign in first so require_login passes
    get root_path, headers: headers
    post "/auth/hackclub", headers: headers
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    user = User.find(session[:user_id])

    org = Organisation.create!(user: user, signing_user: user, users: [ user ])
    event = org.events.create!(name: "Test", capacity: 10)
    attendee = event.attendees.create!(name: "Bob", age: 30)

    get dashboard_events_attendees_organisation_path(org), headers: headers
    assert_response :success
    assert_select "td", text: /Bob/  # attendee name appears
  end

  test "dashboard attendee can be edited" do
    # sign in again
    get root_path, headers: headers
    post "/auth/hackclub", headers: headers
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    user = User.find(session[:user_id])

    org = Organisation.create!(user: user, signing_user: user, users: [ user ])
    event = org.events.create!(name: "Test", capacity: 10)
    attendee = event.attendees.create!(name: "Bob", age: 30)

    # navigate to edit page
    get edit_attendee_organisation_event_path(org, event, attendee_id: attendee.id), headers: headers
    assert_response :success
    assert_select "form" do
      assert_select "input[name='attendee[name]'][value='Bob']"
    end

    # perform update
    patch attendee_organisation_event_path(org, event, attendee_id: attendee.id),
          params: { attendee: { name: "Robert", age: 31 } },
          headers: headers
    assert_redirected_to attendee_organisation_event_path(org, event, attendee_id: attendee.id)
    follow_redirect!
    assert_select "p", text: /Robert/  # updated name shown
  end

  test "public apply endpoint creates attendee" do
    org = Organisation.create!(user: User.create!(name: "U", email: "u@example.com", provider: "hackclub", uid: "u1"), signing_user: User.last, users: [ User.last ])
    event = org.events.create!(name: "OpenEvent", capacity: 5)

    post public_apply_event_path(event.apply_token), params: { attendee: { name: "Sam", email: "sam@example.com" } }
    assert_response :created
    assert_equal 1, event.reload.attendees.count
  end

  test "nested apply endpoint creates attendee" do
    org = Organisation.create!(user: User.create!(name: "V", email: "v@example.com", provider: "hackclub", uid: "v1"), signing_user: User.last, users: [ User.last ])
    event = org.events.create!(name: "PrivateEvent", capacity: 5)

    post apply_organisation_event_path(org, event), params: { attendee: { name: "Jill", email: "jill@example.com" } }
    assert_response :created
    assert_equal 1, event.reload.attendees.count
  end
  test "public qr page renders attendee info" do
    user = User.create!(name: "A", email: "a@example.com", provider: "hackclub", uid: "u1")
    org = Organisation.create!(user: user, signing_user: user, users: [ user ])
    event = org.events.create!(name: "Test", capacity: 10)
    attendee = event.attendees.create!(name: "Bob", email: "bob@example.com")

    get public_qr_code_path(attendee.code)
    assert_response :success
    assert_select "h1", text: /Bob/  # header shows attendee name
    assert_select "strong", text: /Event:/
    # layout should be skipped; application header text not present
    assert_select "header", count: 0
  end
  test "sending qr codes enqueues mailer jobs" do
    get root_path, headers: headers
    post "/auth/hackclub", headers: headers
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    user = User.find(session[:user_id])

    org = Organisation.create!(user: user, signing_user: user, users: [ user ])
    event = org.events.create!(name: "Test", capacity: 10)
    event.attendees.create!(name: "Alice", email: "alice@example.com")

    # run jobs inline so the mail gets delivered automatically
    perform_enqueued_jobs do
      post send_qr_codes_organisation_event_path(org, event), headers: headers
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "alice@example.com" ], mail.to
    assert_match(/QR code/, mail.subject)
  end
end
