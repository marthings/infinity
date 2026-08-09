require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "normalizes names for user-scoped uniqueness" do
    tag = Tag.new(user: users(:one), name: "  Design  ")

    assert_equal "design", tag.name
    assert_not tag.valid?
    assert_predicate tag.errors[:name], :any?
  end
end
