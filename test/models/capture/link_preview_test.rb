require "test_helper"
require "test_helpers/link_preview_http_helper"

class Capture::LinkPreviewTest < ActiveSupport::TestCase
  include LinkPreviewHttpHelper

  test "parses Open Graph metadata including the image URL" do
    preview = Capture::LinkPreview.parse(<<~HTML)
      <html>
        <head>
          <meta property="og:title" content="A useful article">
          <meta property="og:description" content="A concise summary">
          <meta property="og:site_name" content="Example">
          <meta property="og:image" content="https://images.example.com/og.png">
          <title>Fallback title</title>
        </head>
      </html>
    HTML

    assert_equal "A useful article", preview.title
    assert_equal "A concise summary", preview.description
    assert_equal "Example", preview.source_name
    assert_equal "https://images.example.com/og.png", preview.image_url
    assert_nil preview.image
  end

  test "rejects private destinations before requesting them" do
    [ "http://127.0.0.1", "http://[::ffff:127.0.0.1]" ].each do |source_url|
      assert_raises Capture::LinkPreview::UnsafeUrl do
        Capture::LinkPreview.fetch(source_url)
      end
    end
  end

  test "downloads a local preview image from Open Graph" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "https://images.example.com/og.png"), content_type: "text/html" },
      "https://images.example.com/og.png" => { status: 200, body: MINIMAL_PNG, content_type: "image/png" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "A useful article", preview.title
      assert_equal "https://images.example.com/og.png", preview.image_url
      assert_equal "image/png", preview.image.content_type
      assert_equal "og.png", preview.image.filename
      assert_equal MINIMAL_PNG, preview.image.io.read
    end
  end

  test "resolves a relative Open Graph image against the page URL" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "/images/og.png"), content_type: "text/html" },
      "https://www.example.com/images/og.png" => { status: 200, body: MINIMAL_PNG, content_type: "image/png" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "https://www.example.com/images/og.png", preview.image_url
      assert_equal MINIMAL_PNG, preview.image.io.read
    end
  end

  test "uses a YouTube thumbnail when Open Graph has no image" do
    stub_link_preview_http(
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => { status: 200, body: preview_html(title: "A video", site_name: nil, image_url: nil), content_type: "text/html" },
      "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg" => { status: 200, body: MINIMAL_PNG, content_type: "image/png" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

      assert_equal "A video", preview.title
      assert_equal "YouTube", preview.source_name
      assert_equal "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg", preview.image_url
      assert_equal "image/png", preview.image.content_type
    end
  end

  test "prefers an Open Graph image over the YouTube thumbnail fallback" do
    stub_link_preview_http(
      "https://youtu.be/dQw4w9WgXcQ" => { status: 200, body: preview_html(title: "A video", site_name: "YouTube", image_url: "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"), content_type: "text/html" },
      "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg" => { status: 200, body: MINIMAL_PNG, content_type: "image/png" }
    ) do
      preview = Capture::LinkPreview.fetch("https://youtu.be/dQw4w9WgXcQ")

      assert_equal "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg", preview.image_url
      assert preview.image
    end
  end

  test "keeps text metadata when a preview image URL is unsafe" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "http://127.0.0.1/secret.png"), content_type: "text/html" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "A useful article", preview.title
      assert_nil preview.image
    end
  end

  test "keeps text metadata when a preview image is too large" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "https://images.example.com/og.png"), content_type: "text/html" },
      "https://images.example.com/og.png" => { status: 200, body: MINIMAL_PNG, content_type: "image/png", content_length: 6.megabytes }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "A useful article", preview.title
      assert_nil preview.image
    end
  end

  test "keeps text metadata when a preview image has a bad content type" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "https://images.example.com/og.png"), content_type: "text/html" },
      "https://images.example.com/og.png" => { status: 200, body: "<html>not an image</html>", content_type: "text/html" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "A useful article", preview.title
      assert_nil preview.image
    end
  end

  test "rejects a spoofed image content type" do
    stub_link_preview_http(
      "https://www.example.com/article" => { status: 200, body: preview_html(image_url: "https://images.example.com/og.png"), content_type: "text/html" },
      "https://images.example.com/og.png" => { status: 200, body: "<html>not an image</html>", content_type: "image/jpeg" }
    ) do
      preview = Capture::LinkPreview.fetch("https://www.example.com/article")

      assert_equal "A useful article", preview.title
      assert_nil preview.image
    end
  end
end
