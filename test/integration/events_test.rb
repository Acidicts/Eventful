require "test_helper"

class EventsTest < ActionDispatch::IntegrationTest
  test "top-level events path is reachable" do
    # no data required; index should still render (empty list)
    get events_path
    assert_response :success
  end

  test "nested events index still works" do
    user = User.create!(name: "Foo", email: "foo@example.com", provider: "hackclub", uid: "u1")
    org  = Organisation.create!(user: user, signing_user: user, users: [ user ])

    get organisation_events_path(org)
    assert_response :success
  end
end
