require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "requires a name" do
    collection = Collection.new(user: users(:one), name: " ")

    assert_not collection.valid?
    assert_predicate collection.errors[:name], :any?
  end

  test "returns captures in placement order" do
    later_capture = Capture.create!(user: users(:one), note: "A later idea")
    CollectionCapture.create!(collection: collections(:inspiration), capture: later_capture)

    assert_equal [ captures(:link), later_capture ], collections(:inspiration).captures.to_a
  end
end
