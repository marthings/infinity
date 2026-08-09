require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a valid email_address" do
    user = User.new(email_address: "invalid", password: "password", password_confirmation: "password")

    assert_not user.valid?
    assert_predicate user.errors[:email_address], :any?
  end
end
