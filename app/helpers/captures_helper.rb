module CapturesHelper
  def capture_preview_alt(capture)
    capture.title.presence || capture.source_name.presence || "Saved capture"
  end

  def safe_source_url(source_url)
    return if source_url.blank?

    uri = URI.parse(source_url)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
