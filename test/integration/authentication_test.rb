require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  # This test doesn't need any database fixtures; we disabled the global
  # fixtures load in test_helper so nothing will be inserted.

  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: "int123",
      info: {
        name: "Integration User",
        email: "int@example.com",
        slack_id: "U789",
        verification_status: "verified",
        admin: false
      },
      credentials: {
        token: "token123",
        refresh_token: "refresh123",
        expires_at: 1.day.from_now.to_i
      }
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
  end

  test "sign in and sign out flow" do
    get root_path
    assert_response :success

    # the app should allow initiating auth via POST (button_to)
    post "/auth/hackclub"
    assert_response :redirect

    # simulate callback from provider
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Signed in successfully", flash[:notice]
    assert session[:user_id].present?

    # ensure credentials are stored as per the migration above
    user = User.find(session[:user_id])
    assert_equal "token123", user.access_token
    assert_equal "refresh123", user.refresh_token
    assert user.expires_at > Time.current
    assert_equal "member", user.role

    # test both DELETE and GET variants – both should clear the session
    delete logout_path
    assert_nil session[:user_id]
    # log back in so we can try GET route
    post "/auth/hackclub", headers: headers
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!
    get logout_path
    assert_nil session[:user_id]
    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Signed out", flash[:notice]
    assert_nil session[:user_id]
  end

  test "omniauth failure redirects safely with user-friendly message" do
    get "/auth/failure", params: {
      message: "timeout",
      origin: "https://eventful.bing-bong.uk/",
      strategy: "hackclub"
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Sign in with Hackclub failed (Timeout). Please try again.", flash[:alert]
    assert_nil session[:user_id]
  end
end
