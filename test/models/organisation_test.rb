require "test_helper"

class OrganisationTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Test", email: "test@example.com", provider: "hackclub", uid: "u1")
  end

  test "requires a signing user" do
    org = Organisation.new(user: @user)
    assert_not org.valid?
    assert_includes org.errors[:signing_user], "can't be blank"
  end

  test "signing user must be a member" do
    other = User.create!(name: "Other", email: "other@example.com", provider: "hackclub", uid: "u2")
    org = Organisation.new(user: @user, signing_user: other)

    assert_not org.valid?
    assert_includes org.errors[:signing_user], "must belong to this organisation"

    # if we add membership manually it becomes valid
    org.users << other
    assert org.valid?
  end

  test "for_user scope includes signing user even when not a member" do
    org = Organisation.create!(user: @user, signing_user: @user, users: [ @user ])
    # simulate a later edit that drops membership but leaves signing user
    org.users.delete(@user)
    assert_not org.users.include?(@user)

    assert_includes Organisation.for_user(@user), org
  end
  test "attributes img, description and self_found are assignable" do
    org = Organisation.new(user: @user, signing_user: @user)
    # signing user must also be a member for validation to pass
    org.users << @user

    org.img = "http://example.com/hero.png"
    org.description = "A cool organization"
    org.self_found = true
    assert org.valid?
    assert_equal "http://example.com/hero.png", org.img
    assert_equal "A cool organization", org.description
    assert org.self_found
  end

  test "self_found flag auto-assigns signing user and membership" do
    org = Organisation.new(user: @user, self_found: true)
    # we haven't manually added the signing user or membership yet;
    # validation+callback should take care of both.
    assert org.valid?, org.errors.full_messages.join(", ")
    assert_equal @user, org.signing_user
    assert_includes org.users, @user
  end
end
