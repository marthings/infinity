require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "prevents duplicate tags on a capture" do
    tagging = Tagging.new(tag: tags(:design), capture: captures(:link))

    assert_not tagging.valid?
    assert_predicate tagging.errors[:capture_id], :any?
  end

  test "prevents tags across users" do
    tagging = Tagging.new(tag: tags(:design), capture: captures(:note))

    assert_not tagging.valid?
    assert_predicate tagging.errors[:capture], :any?
  end
end
