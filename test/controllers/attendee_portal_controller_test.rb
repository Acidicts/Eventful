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

  test "auto sign in via code query param on index" do
    # visiting the portal with ?code= should create a session and land on
    # the portal page without requiring a separate POST to the login action.
    get attendee_portal_path(code: @attendee.code)
    # routing may issue a normalization redirect (trailing slash) so follow
    # any redirect before asserting success.
    if response.redirect?
      follow_redirect!
    end

    assert_response :success
    assert_equal @attendee.id, session[:attendee_id]
  end

  # qr_code is now protected by authentication; unauthenticated requests
  # should be redirected to the login page rather than rendering our
  # previous "not found" placeholder.
  test "qr_code requires login" do
    get attendee_portal_qr_code_path
    assert_redirected_to attendee_portal_login_path
  end

  test "waiver route requires login" do
    get attendee_portal_waiver_path
    assert_redirected_to attendee_portal_login_path

    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!
    get attendee_portal_waiver_path
    assert_response :success
  end

  test "qr_code action renders svg when logged in" do
    # unauthenticated users should be redirected to login
    get attendee_portal_qr_code_path
    assert_redirected_to attendee_portal_login_path

    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!
    get attendee_portal_qr_code_path
    assert_response :success
    svg = @response.body
    assert_includes svg, "<svg" # basic sanity
    assert_no_match /<\?xml/, svg
    assert_match(/viewBox="0 0 \d+ \d+"/, svg)
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

  test "contact action returns attendee messages" do
    # log in first
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    # create a message record using raw ids to avoid missing Reciever model
    Message.create!(sender_id: @attendee.id, reciever_id: @attendee.id, reciever_type: "Attendee", message: "hello")

    # sanity check the record exists and the query will match
    matching = Message.where(sender: @attendee)
                      .or(Message.where(reciever: @attendee))
    assert_equal 1, matching.count, "expected one message in query, got \\#{matching.count} (sql: \\#{matching.to_sql})"

    get attendee_portal_contact_path
    assert_response :success
    assert_select "#queries .message p", text: /hello/  # contains message text
  end
  test "submitting contact form creates message and redirects" do
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    assert_difference "Message.count", 1 do
      post attendee_portal_contact_path, params: { message: "new note" }
    end
    assert_redirected_to attendee_portal_contact_path
    follow_redirect!
    assert_select "#queries .message p", text: /new note/
  end
end
