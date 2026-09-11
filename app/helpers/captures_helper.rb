module CapturesHelper
  UPLOAD_VARIANTS = {
    inbox: { resize_to_limit: [ 640, 640 ] },
    detail: { resize_to_limit: [ 1280, 1280 ] }
  }.freeze

  def safe_source_url(source_url)
    return if source_url.blank?

    uri = URI.parse(source_url)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def capture_upload_representation(upload, size: :inbox)
    return unless upload.representable?

    upload.representation(UPLOAD_VARIANTS.fetch(size))
  end

  def capture_upload_media_type(upload)
    upload.content_type.presence || "Unknown type"
  end
end
