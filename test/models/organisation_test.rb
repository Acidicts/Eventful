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

  test "signing user is assigned signing role and not member role" do
    org = Organisation.create!(user: @user, signing_user: @user, users: [ @user ])

    @user.reload
    assert @user.organisation_roles.exists?(organisation: org, name: "Signing User"), "expected signing user to have Signing User role"
    assert_not @user.organisation_roles.exists?(organisation: org, name: "Member"), "expected signing user to not have Member role"
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

  test "child members inherit limited parent access role" do
    Organisation::PARENT_SUB_TEAM_MEMBER_ALLOWED_PERMISSIONS.each do |permission|
      RolePermission.find_or_create_by!(permission: permission)
    end

    parent_owner = User.create!(name: "Parent", email: "parent@example.com", provider: "hackclub", uid: "u-parent")
    child_user = User.create!(name: "Child", email: "child@example.com", provider: "hackclub", uid: "u-child")

    parent_org = Organisation.create!(user: parent_owner, signing_user: parent_owner, users: [ parent_owner ])
    Organisation.create!(user: child_user, signing_user: child_user, users: [ child_user ], parent_org: parent_org)

    sub_team_role = OrganisationRole.find_by!(organisation: parent_org, name: "Sub Team Member")
    assert_includes sub_team_role.users, child_user
    assert_not child_user.organisation_roles.exists?(organisation: parent_org, name: "Member")

    assert_equal Organisation::PARENT_SUB_TEAM_MEMBER_ALLOWED_PERMISSIONS.sort,
                 sub_team_role.role_permissions.pluck(:permission).sort
  end

  test "removing a non-signing member revokes organisation role assignments" do
    member = User.create!(name: "Member", email: "member@example.com", provider: "hackclub", uid: "u-member")
    org = Organisation.create!(user: @user, signing_user: @user, users: [ @user, member ])

    custom_role = OrganisationRole.create!(organisation: org, name: "Volunteer")
    custom_role.users << member

    assert member.organisation_roles.exists?(organisation: org, name: "Member")
    assert member.organisation_roles.exists?(organisation: org, name: "Volunteer")

    org.users.delete(member)
    member.reload

    assert_not member.organisation_roles.exists?(organisation: org), "expected removed member to lose organisation role assignments"
  end

  test "destroying an organisation cleans up dependent records" do
    org = Organisation.create!(user: @user, signing_user: @user, users: [ @user ])
    event = org.events.create!(name: "Example", location: "Nowhere", start_date: Time.current, end_date: 1.hour.from_now)
    gallery = org.galleries.create!(public: true)
    Announcement.create!(creator: @user, organisation: org, event: event, content: "Hi")

    assert_difference -> { Organisation.count }, -1 do
      org.destroy
    end

    assert_not Event.exists?(event.id)
    assert_not Gallery.exists?(gallery.id)
    assert_not Announcement.exists?(organisation_id: org.id)

    @user.reload
    assert_nil @user.organisation_id
  end
end
