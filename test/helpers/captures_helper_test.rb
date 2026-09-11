require "test_helper"

class CapturesHelperTest < ActionView::TestCase
  test "uses the capture title as preview alternative text" do
    assert_equal "A saved link", capture_preview_alt(captures(:link))
    assert_equal "Saved capture", capture_preview_alt(Capture.new)
  end

  test "returns absolute HTTP and HTTPS URLs" do
    assert_equal "http://example.com", safe_source_url("http://example.com")
    assert_equal "https://example.com/inspiration", safe_source_url("https://example.com/inspiration")
  end

  test "rejects unsafe URLs" do
    assert_nil safe_source_url("javascript:alert(1)")
    assert_nil safe_source_url("file:///private/inspiration")
  end
end
