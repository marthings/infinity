require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signing up" do
    visit new_registration_path

    fill_in "Email address", with: "new@example.com"
    fill_in "Password", with: "password"
    fill_in "Confirm password", with: "password"
    click_on "Create account"

    assert_current_path root_path
    assert_text "Infinity"
  end
end
