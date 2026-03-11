require "test_helper"

class AttendeePortalTest < ActionDispatch::IntegrationTest
  setup do
    # create a dummy event (minimal) so attendee validations pass
    user = User.create!(provider: "hackclub", uid: "u1")
    # org needs signing_user to be a member as well
    org  = Organisation.create!(user: user, signing_user: user, users: [ user ])
    @event = Event.create!(name: "Test Event", organisation: org, capacity: 10)
    # add a waiver file so portal pages can surface it
    @event.waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.txt")),
      filename: "sample.txt",
      content_type: "text/plain"
    )
    @attendee = Attendee.create!(name: "Example", age: 30, event: @event)
    # code is generated via callback, ensure it's present
    @attendee.reload
    assert @attendee.code.present?, "attendee should have a code"
  end

  test "able to log in with valid code and see portal" do
    get attendee_portal_login_path
    assert_response :success
    assert_select "form"

    post attendee_portal_login_path, params: { code: @attendee.code }
    assert_redirected_to attendee_portal_path
    follow_redirect!
    # page should include event name as header
    assert_select "h1", @event.name
    # and a link to the waiver since one was attached
    assert_select "a", /Download event waiver/
    assert_equal @attendee.id, session[:attendee_id]

    # logout
    delete attendee_portal_logout_path
    assert_nil session[:attendee_id]
    assert_redirected_to attendee_portal_login_path
  end

  test "invalid code shows error" do
    post attendee_portal_login_path, params: { code: "bad" }
    assert_response :unprocessable_entity
    assert_select ".alert", /Invalid code/
    assert_nil session[:attendee_id]
  end

  test "old underscore URL redirects" do
    get "/attendee_portal"
    assert_response :redirect
    assert_redirected_to "/attendee-portal"
  end

  test "profile can be edited from portal without leaving page" do
    # log in first
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    patch attendee_portal_path, params: { attendee: { email: "new@example.com", age: 35 } }
    assert_redirected_to attendee_portal_path
    assert_equal "Profile updated successfully.", flash[:notice]
    @attendee.reload
    assert_equal "new@example.com", @attendee.email
    assert_equal 35, @attendee.age
  end

  test "can view waiver page when logged in" do
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    get attendee_portal_waiver_path
    assert_response :success
    assert_select "a", /Download waiver/ # page should render download link
  end

  test "can sign waiver" do
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    patch attendee_portal_waiver_path, params: {
      attendee: {
        waiver_signature: "Example Person",
        signed_waiver: fixture_file_upload(
          Rails.root.join("test/fixtures/files/sample.txt"),
          "text/plain"
        )
      }
    }
    assert_redirected_to attendee_portal_waiver_path
    follow_redirect!
    # since record is signed we show the signed view (attendee copy iframe)
    @attendee.reload
    assert_select "iframe"   # just ensure preview appears
    assert @attendee.waiver_signed?
    assert_equal "Example Person", @attendee.waiver_signature
    assert @attendee.signed_waiver.attached?
  end

  test "signature alone generates PDF copy" do
    # also verify under‑18 flow
    @attendee.update!(age: 17)
    # attach a PDF waiver to the event so generation has something to use
    @event.waiver.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.pdf")),
      filename: "waiver.pdf",
      content_type: "application/pdf"
    )

    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    patch attendee_portal_waiver_path, params: { attendee: { waiver_signature: "Joe", under_18: true, parent_signature: "Mom" } }
    assert_redirected_to attendee_portal_waiver_path
    follow_redirect!

    @attendee.reload
    assert @attendee.signed_waiver.attached?
    assert_equal "application/pdf", @attendee.signed_waiver.content_type
    # content should include signature text
    # verify generated PDF page contains the signature text
    # PDF binaries encode text operations; look for hex representation
    assert_match /4d6f6d/, @attendee.signed_waiver.download # 'Mom' in hex (parent signature)
  end

  test "waiver page hides form after signing" do
    @attendee.update!(waiver_signed: true, waiver_signed_at: 1.day.ago, waiver_signature: "Signed")
    assert @attendee.waiver_signed?, "setup should have marked waiver_signed"
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    # signed user redirected to signed view without form
    assert_select "iframe"
    assert_select "input[type=submit][value='Sign Waiver']", 0
  end

  test "submission without signature or file shows error" do
    post attendee_portal_login_path, params: { code: @attendee.code }
    follow_redirect!

    patch attendee_portal_waiver_path, params: { attendee: { waiver_signature: "" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation", /Please provide your name or upload the signed waiver/
  end
end
