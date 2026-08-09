require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path

    assert_response :success
  end

  test "create with valid credentials" do
    assert_difference -> { User.count }, +1 do
      post registration_path, params: { registration: { email_address: "new@example.com", password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { registration: { email_address: "invalid", password: "password", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /Unable to create your account/
  end

  test "create with an existing email address" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { registration: { email_address: users(:one).email_address, password: "password", password_confirmation: "password" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /Unable to create an account/
  end
end
