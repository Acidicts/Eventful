require "test_helper"

class OrganisationsTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: "int123",
      info: {
        name: "Org Creator",
        email: "org@example.com",
        slack_id: "U999",
        verification_status: "verified",
        admin: false
      },
      credentials: {
        token: "token999",
        refresh_token: "refresh999",
        expires_at: 1.day.from_now.to_i
      }
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
  end

  test "creating an organisation assigns the current user" do
    # sign the test user in
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    assert_equal "Signed in successfully", flash[:notice]
    user = User.find(session[:user_id])

    # creating an organisation no longer requires an associated event,
    # but the form still submits the hidden `user_id` field so include that
    # here to satisfy `params.require(:organisation)`.
    # with `self_found` checked we should not need to supply a signing user;
    # the controller/model logic will automatically make the creator the
    # signing user and add them to the membership list.
    post organisations_path, params: { organisation: { user_id: user.id, name: "Acme", description: "An acme org", img: "http://img.example/1.png", self_found: true } }
    assert_response :redirect
    assert_equal "Organisation was successfully created.", flash[:notice]

    org = Organisation.last
    assert_equal user.id, org.user_id, "the creator should be associated as the owner"
    assert_equal user.id, org.signing_user_id, "self_found should make the creator the signing user"
    assert_includes org.users, user, "signing user should automatically be added as a member"
  end

  test "superadmin is excluded from signing user dropdown" do
    # sign in so we can reach the new page (require_login applies)
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!

    # make a normal user and a superadmin candidate
    normal = User.create!(name: "Normal", email: "norm@example.com", provider: "hackclub", uid: "u2")
    User.create!(name: "Super", email: "super@example.com", provider: "hackclub", uid: "u3", role: :superadmin)

    # load new form; @users comes from controller filter
    get new_organisation_path
    assert_response :success

    # the dropdown should include normal user and exclude superadmin
    assert_select "select[name='organisation[signing_user_id]'] option", text: /Normal/
    assert_select "select[name='organisation[signing_user_id]'] option", { text: /Super/, count: 0 }
  end

  test "signing user sees organisation in index even when removed from members" do
    # sign in as test user
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    user = User.find(session[:user_id])

    # create organisation where the user is both owner and signing user
    org = Organisation.create!(user: user, signing_user: user, users: [ user ], img: "http://img.example/1.png")
    # then strip them out of the membership list
    org.users.delete(user)

    get organisations_path
    assert_response :success
    # partial renders basic attributes and should include image tag when img present
    assert_select ".event-card__icon[src='http://img.example/1.png']"
  end

  test "child member can view parent dashboard and create sub teams but cannot edit parent org" do
    # sign in as child-team user
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    child_user = User.find(session[:user_id])

    parent_user = User.create!(name: "Parent Owner", email: "parent-owner@example.com", provider: "hackclub", uid: "parent-owner")
    parent_org = Organisation.create!(user: parent_user, signing_user: parent_user, users: [ parent_user ], name: "Parent Org")

    Organisation.create!(user: child_user, signing_user: child_user, users: [ child_user ], parent_org: parent_org, name: "Child Org")

    get dashboard_organisation_path(parent_org)
    assert_response :success

    get edit_organisation_path(parent_org)
    assert_response :redirect
    assert_equal "You do not have permission to perform this action.", flash[:alert]

    assert_difference -> { parent_org.sub_teams.count }, 1 do
      post dashboard_sub_teams_create_organisation_path(parent_org), params: {
        organisation: {
          name: "Ops Team",
          description: "Created by inherited sub-team role"
        }
      }
    end
  end

  test "parent dashboard events link to each event owning organisation" do
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    child_user = User.find(session[:user_id])

    parent_user = User.create!(name: "Parent Owner 2", email: "parent-owner-2@example.com", provider: "hackclub", uid: "parent-owner-2")
    parent_org = Organisation.create!(user: parent_user, signing_user: parent_user, users: [ parent_user ], name: "Parent Org 2")
    child_org = Organisation.create!(user: child_user, signing_user: child_user, users: [ child_user ], parent_org: parent_org, name: "Child Org 2")
    child_event = child_org.events.create!(name: "Child Event", location: "HQ", start_date: Time.current, end_date: 1.hour.from_now)

    get dashboard_events_organisation_path(parent_org)
    assert_response :success
    assert_select "a[href='#{organisation_event_path(child_org, child_event)}']", text: /Child Event/
  end

  test "joining an organisation assigns the member role" do
    # sign in as joining user
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    joining_user = User.find(session[:user_id])

    owner = User.create!(name: "Org Owner", email: "owner@example.com", provider: "hackclub", uid: "owner-1")
    parent_org = Organisation.create!(user: owner, signing_user: owner, users: [ owner, joining_user ], name: "Parent Org")
    org = Organisation.create!(user: owner, signing_user: owner, users: [ owner ], parent_org: parent_org, name: "Joinable Sub Team")

    get join_organisation_path(org)
    assert_response :redirect

    joining_user.reload
    assert joining_user.organisation_roles.exists?(organisation: org, name: "Member"), "expected joining user to receive Member role"
  end

  test "sub-team member added later can traverse parent to child dashboard" do
    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    member_user = User.find(session[:user_id])

    parent_owner = User.create!(name: "Parent Owner 3", email: "parent-owner-3@example.com", provider: "hackclub", uid: "parent-owner-3")
    child_owner = User.create!(name: "Child Owner 3", email: "child-owner-3@example.com", provider: "hackclub", uid: "child-owner-3")

    parent_org = Organisation.create!(user: parent_owner, signing_user: parent_owner, users: [ parent_owner ], name: "Parent Org 3")
    child_org = Organisation.create!(user: child_owner, signing_user: child_owner, users: [ child_owner ], parent_org: parent_org, name: "Child Org 3")

    # Add this member after the child team already exists to simulate stale
    # parent-role sync state.
    child_org.users << member_user unless child_org.users.include?(member_user)

    get dashboard_organisation_path(parent_org)
    assert_response :success

    get dashboard_organisation_path(child_org)
    assert_response :success
  end
end
