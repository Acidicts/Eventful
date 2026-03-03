require "test_helper"

class UserTest < ActiveSupport::TestCase
  # only the user tests need fixtures
  fixtures :users
  test "from_omniauth creates a new user" do
    auth = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: "abc123",
      info: {
        name: "Jane Doe",
        email: "jane@example.com",
        slack_id: "U456",
        verification_status: "verified",
        admin: true
      }
    )

    assert_difference "User.count", 1 do
      @user = User.from_omniauth(auth)
    end

    assert @user.persisted?
    assert_equal "abc123", @user.uid
    assert_equal "Jane Doe", @user.name
    assert_equal "jane@example.com", @user.email
    assert @user.admin
  end

  test "from_omniauth updates an existing user" do
    existing = users(:one)
    auth = OmniAuth::AuthHash.new(
      provider: existing.provider,
      uid: existing.uid,
      info: {
        name: "Updated Name",
        email: "new@example.com",
        slack_id: "U999",
        verification_status: "unverified",
        admin: true
      }
    )

    user = User.from_omniauth(auth)
    assert_equal existing.id, user.id
    assert_equal "Updated Name", user.name
    assert_equal "new@example.com", user.email
    assert user.admin
  end

    test "from_omniauth stores credentials" do
      auth = OmniAuth::AuthHash.new(
        provider: "hackclub",
        uid: "tok123",
        info: {
          name: "Cred User",
          email: "cred@example.com",
          slack_id: "U000",
          verification_status: "verified",
          admin: false
        },
        credentials: {
          token: "atoken",
          refresh_token: "rtoken",
          expires_at: 1.hour.from_now.to_i
        }
      )

      user = User.from_omniauth(auth)
      assert_equal "atoken", user.access_token
      assert_equal "rtoken", user.refresh_token
      assert user.expires_at > Time.current
    end
  end
