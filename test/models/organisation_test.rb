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
end
