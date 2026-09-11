require "test_helper"

class EnrichCaptureLinkJobTest < ActiveJob::TestCase
  test "attaches a fetched preview image to the capture" do
    capture = captures(:link)
    image = Capture::LinkPreview::Image.new(
      io: file_fixture("preview.png").open,
      filename: "preview.png",
      content_type: "image/png"
    )
    preview = Capture::LinkPreview::Preview.new("An example article", "A useful description", "Example", "https://example.com/og.png", image)

    Capture::LinkPreview.stub(:fetch, preview) do
      EnrichCaptureLinkJob.perform_now(capture)
    end

    assert_predicate capture.reload.preview_image, :attached?
    assert_equal "preview.png", capture.preview_image.filename.to_s
    assert_equal users(:one), capture.user
  end

  test "leaves the capture usable when enrichment fails" do
    capture = captures(:link)

    Capture::LinkPreview.stub(:fetch, ->(*) { raise Capture::LinkPreview::UnsafeUrl }) do
      EnrichCaptureLinkJob.perform_now(capture)
    end

    capture.reload
    assert_equal "A saved link", capture.title
    assert_not capture.preview_image.attached?
  end
end
