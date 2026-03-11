require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess

  setup do
    user = User.create!(provider: "hackclub", uid: SecureRandom.hex)
    @organisation = Organisation.create!(user: user, signing_user: user, users: [ user ])
    @event = Event.create!(name: "Sample", organisation: @organisation, capacity: 5)
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
