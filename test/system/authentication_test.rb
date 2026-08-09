require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signing in" do
    visit new_session_path

    fill_in :email_address, with: users(:one).email_address
    fill_in :password, with: "password"
    click_on "Sign in"

    assert_current_path root_path
    assert_text "Infinity"
  end
end
