require "test_helper"

class Capture::LinkPreviewTest < ActiveSupport::TestCase
  test "parses Open Graph metadata" do
    preview = Capture::LinkPreview.parse(<<~HTML)
      <html>
        <head>
          <meta property="og:title" content="A useful article">
          <meta property="og:description" content="A concise summary">
          <meta property="og:site_name" content="Example">
          <title>Fallback title</title>
        </head>
      </html>
    HTML

    assert_equal "A useful article", preview.title
    assert_equal "A concise summary", preview.description
    assert_equal "Example", preview.source_name
  end

  test "rejects private destinations before requesting them" do
    [ "http://127.0.0.1", "http://[::ffff:127.0.0.1]" ].each do |source_url|
      assert_raises Capture::LinkPreview::UnsafeUrl do
        Capture::LinkPreview.fetch(source_url)
      end
    end
  end
end
