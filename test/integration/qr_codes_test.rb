require "test_helper"

class QrCodesTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: "qr-int-123",
      info: {
        name: "QR User",
        email: "qr-user@example.com",
        admin: false
      },
      credentials: {
        token: "tok",
        refresh_token: "ref",
        expires_at: 1.day.from_now.to_i
      }
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
  end

  def sign_in_and_seed_permissions
    user = User.find_or_create_by!(provider: "hackclub", uid: "qr-int-123") do |u|
      u.name = "QR User"
      u.email = "qr-user@example.com"
    end

    get root_path
    post "/auth/hackclub"
    get "/auth/hackclub/callback", env: { "omniauth.auth" => OmniAuth.config.mock_auth[:hackclub] }
    follow_redirect!

    org = Organisation.find_or_create_by!(user: user, signing_user: user, name: "QR Org") do |record|
      record.users = [ user ]
    end
    org.users << user unless org.users.include?(user)
    org.give_all_users_roles
  end

  test "generator form displays and generates" do
    sign_in_and_seed_permissions

    get new_qr_code_path
    assert_response :success
    assert_select "form"

    post qr_code_path, params: { data: "TEST123" }
    assert_redirected_to new_qr_code_path(data: "TEST123")

    follow_redirect!
    assert_select ".qr-output svg"
  end

  test "decode page renders camera element" do
    sign_in_and_seed_permissions

    get decode_qr_code_path
    assert_response :success
    assert_select "video"
  end
end
