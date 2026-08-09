require "test_helper"

class CaptureTest < ActiveSupport::TestCase
  test "belongs to its user" do
    assert_equal users(:one), captures(:link).user
  end

  test "requires a user" do
    capture = Capture.new(note: "A private thought")

    assert_not capture.valid?
    assert_predicate capture.errors[:user], :any?
  end

  test "requires meaningful content" do
    capture = Capture.new(user: users(:one))

    assert_not capture.valid?
    assert_predicate capture.errors[:base], :any?
  end

  test "accepts an upload as meaningful content" do
    capture = Capture.new(user: users(:one))
    capture.uploads.attach(io: StringIO.new("inspiration"), filename: "inspiration.txt", content_type: "text/plain")

    assert_predicate capture, :valid?
  end

  test "generates a title from a link hostname" do
    capture = Capture.new(user: users(:one), source_url: "https://www.youtube.com/watch?v=example")

    assert_predicate capture, :valid?
    assert_equal "youtube.com", capture.title
  end

  test "generates a title from the first uploaded file name" do
    capture = Capture.new(user: users(:one))
    capture.uploads.attach(io: StringIO.new("inspiration"), filename: "gallery-photo.jpg", content_type: "image/jpeg")

    assert_predicate capture, :valid?
    assert_equal "gallery-photo.jpg", capture.title
  end

  test "does not replace an explicit title" do
    capture = Capture.new(user: users(:one), source_url: "https://example.com", title: "My example")

    assert_predicate capture, :valid?
    assert_equal "My example", capture.title
  end

  test "accepts HTTP and HTTPS source URLs" do
    [ "http://example.com", "https://example.com/inspiration" ].each do |source_url|
      capture = Capture.new(user: users(:one), source_url: source_url)

      assert_predicate capture, :valid?
    end
  end

  test "rejects non-web source URLs" do
    capture = Capture.new(user: users(:one), source_url: "file:///private/inspiration")

    assert_not capture.valid?
    assert_predicate capture.errors[:source_url], :any?
  end

  test "normalizes optional text attributes" do
    capture = Capture.new(user: users(:one), title: "  A saved thought  ", source_name: "  Example  ")

    assert_equal "A saved thought", capture.title
    assert_equal "Example", capture.source_name
  end
end
