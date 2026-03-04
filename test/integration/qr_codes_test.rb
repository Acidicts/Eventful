require "test_helper"

class QrCodesTest < ActionDispatch::IntegrationTest
  test "generator form displays and generates" do
    get new_qr_code_path
    assert_response :success
    assert_select "form"

    post qr_code_path, params: { data: "TEST123" }
    assert_redirected_to new_qr_code_path(data: "TEST123")

    follow_redirect!
    assert_select ".qr-output svg"
  end

  test "decode page renders camera element" do
    get decode_qr_code_path
    assert_response :success
    assert_select "video"
  end
end
