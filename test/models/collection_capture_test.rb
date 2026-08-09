require "test_helper"

class CollectionCaptureTest < ActiveSupport::TestCase
  test "places a capture at the end of its collection" do
    later_capture = Capture.create!(user: users(:one), note: "A later idea")

    placement = CollectionCapture.create!(collection: collections(:inspiration), capture: later_capture)

    assert_equal 1, placement.position
  end

  test "prevents duplicate placements" do
    placement = CollectionCapture.new(collection: collections(:inspiration), capture: captures(:link), position: 0)

    assert_not placement.valid?
    assert_predicate placement.errors[:capture_id], :any?
  end

  test "prevents placements across users" do
    placement = CollectionCapture.new(collection: collections(:inspiration), capture: captures(:note), position: 1)

    assert_not placement.valid?
    assert_predicate placement.errors[:capture], :any?
  end
end
