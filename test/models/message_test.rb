require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    org_user = User.create!(provider: "hackclub", uid: SecureRandom.hex)
    @event = Event.create!(name: "Test event", organisation: Organisation.create!(user: org_user, signing_user: org_user, users: [ org_user ]), capacity: 1)
    @attendee = Attendee.create!(name: "Alice", age: 30, event: @event)
  end

  test "can create message without answerer initially" do
    m = Message.new(sender: @attendee, reciever: @attendee, message: "hello")
    assert m.save
    assert_nil m.answerer
  end

  test "can associate answerer user" do
    responder = User.create!(provider: "hackclub", uid: SecureRandom.hex)
    m = Message.create!(sender: @attendee, reciever: @attendee, message: "question", answerer: responder)
    assert_equal responder, m.answerer
  end
end
