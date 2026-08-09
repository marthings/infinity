require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "show" do
    get profile_path

    assert_response :success
    assert_select "meta[name=viewport][content='width=device-width,initial-scale=1,viewport-fit=cover']"
    assert_select "h1", "Profile"
    assert_select "input[value=?]", users(:one).email_address
    assert_select "[data-native-form]"
    assert_select "[data-native-navbar='Profile']"
    assert_select "[data-native-identity]"
    assert_select "main.native-inset"
  end

  test "updates the signed-in user email address" do
    patch profile_path, params: { profile: { email_address: "updated@example.com", password: "", password_confirmation: "" } }

    assert_redirected_to profile_path
    assert_equal "updated@example.com", users(:one).reload.email_address
  end

  test "updates the signed-in user password" do
    patch profile_path, params: { profile: { email_address: users(:one).email_address, password: "updated-password", password_confirmation: "updated-password" } }

    assert_redirected_to profile_path
    assert users(:one).reload.authenticate("updated-password")
  end

  test "renders errors for an invalid profile" do
    patch profile_path, params: { profile: { email_address: "invalid", password: "", password_confirmation: "" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
  end
end
