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
    post organisations_path, params: { organisation: { user_id: user.id, signing_user_id: user.id } }
    assert_response :redirect
    assert_equal "Organisation was successfully created.", flash[:notice]

    org = Organisation.last
    assert_equal user.id, org.user_id, "the creator should be associated as the owner"
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
end
