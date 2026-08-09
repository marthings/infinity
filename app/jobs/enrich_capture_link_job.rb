require "net/http"
require "socket"

class EnrichCaptureLinkJob < ApplicationJob
  retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(capture)
    capture.enrich_link_preview
  end
end
