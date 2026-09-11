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

  test "returns an image variant for a local link preview" do
    capture = captures(:link)
    capture.preview_image.attach(io: file_fixture("preview.png").open, filename: "preview.png", content_type: "image/png")

    representation = capture_preview_representation(capture, size: :inbox)

    assert_equal [ 640, 640 ], representation.variation.transformations[:resize_to_limit]
  end

  test "returns an image variant for variable uploads" do
    upload = attach_upload(captures(:link), "inspiration.png", "image/png")

    representation = capture_upload_representation(upload, size: :inbox)

    assert upload.variable?
    assert_equal [ 640, 640 ], representation.variation.transformations[:resize_to_limit]
  end

  test "returns a larger detail variant for variable uploads" do
    upload = attach_upload(captures(:link), "inspiration.png", "image/png")

    representation = capture_upload_representation(upload, size: :detail)

    assert_equal [ 1280, 1280 ], representation.variation.transformations[:resize_to_limit]
  end

  test "uses a preview when Rails preview tooling can represent the upload" do
    upload = attach_upload(captures(:link), "inspiration.txt", "text/plain")
    preview = Object.new

    upload.define_singleton_method(:representable?) { true }
    upload.define_singleton_method(:representation) { |*_args, **_kwargs| preview }

    assert_equal preview, capture_upload_representation(upload, size: :detail)
  end

  test "returns no representation when the upload is not representable" do
    upload = attach_upload(captures(:link), "inspiration.txt", "text/plain")

    assert_not upload.representable?
    assert_nil capture_upload_representation(upload)
  end

  test "returns a readable media type for fallbacks" do
    upload = attach_upload(captures(:link), "inspiration.txt", "text/plain")

    assert_equal "text/plain", capture_upload_media_type(upload)
  end

  private
    def attach_upload(capture, filename, content_type)
      capture.uploads.attach(
        io: file_fixture(filename).open,
        filename: filename,
        content_type: content_type
      )
      capture.uploads.last
    end
end
