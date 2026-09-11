require "ipaddr"
require "marcel"
require "net/http"
require "nokogiri"
require "socket"
require "stringio"
require "uri"

class Capture::LinkPreview
  Preview = Data.define(:title, :description, :source_name, :image_url, :image) do
    def initialize(title: nil, description: nil, source_name: nil, image_url: nil, image: nil)
      super
    end
  end
  Image = Data.define(:io, :filename, :content_type)

  class UnsafeUrl < StandardError; end
  class UnsupportedResponse < StandardError; end
  class ResponseTooLarge < UnsupportedResponse; end

  MAX_REDIRECTS = 3
  MAX_RESPONSE_BYTES = 1.megabyte
  MAX_IMAGE_BYTES = 5.megabytes
  OPEN_TIMEOUT = 3.seconds
  READ_TIMEOUT = 5.seconds
  USER_AGENT = "Infinity link preview/1.0"
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com music.youtube.com youtu.be www.youtu.be].freeze
  YOUTUBE_VIDEO_ID = /\A[\w-]{11}\z/
  IMAGE_FILENAME = /\A[\w.-]+\.(jpe?g|png|gif|webp)\z/i
  IMAGE_EXTENSIONS = {
    "image/jpeg" => "jpg",
    "image/png" => "png",
    "image/gif" => "gif",
    "image/webp" => "webp"
  }.freeze

  def self.fetch(source_url)
    new(source_url).fetch
  end

  def self.parse(html)
    document = Nokogiri::HTML5.parse(html)

    Preview.new(
      metadata(document, "og:title") || text_at(document, "title"),
      metadata(document, "og:description") || metadata(document, "description", attribute: "name"),
      metadata(document, "og:site_name"),
      image_metadata(document)
    )
  end

  def initialize(source_url)
    @source_url = source_url
  end

  def fetch
    document_uri, html = fetch_document
    return unless html

    parsed = self.class.parse(html)
    source_uri = parse_uri(@source_url)
    image_url = absolute_url(document_uri, parsed.image_url) || youtube_thumbnail_url(document_uri, source_uri)

    Preview.new(
      parsed.title,
      parsed.description,
      parsed.source_name || youtube_source_name(document_uri, source_uri),
      image_url,
      download_image(image_url)
    )
  end

  private
    def self.metadata(document, property, attribute: "property")
      normalize(document.at_css(%(meta[#{attribute}="#{property}"]))&.[]("content"))
    end

    def self.image_metadata(document)
      document.at_css(%(meta[property="og:image"]))&.[]("content")&.strip.presence
    end

    def self.text_at(document, selector)
      normalize(document.at_css(selector)&.text)
    end

    def self.normalize(value)
      value.to_s.squish.presence&.truncate(300)
    end

    def fetch_document
      uri = parse_uri(@source_url)

      MAX_REDIRECTS.times do
        response = response_for(uri, accept: "text/html,application/xhtml+xml", max_bytes: MAX_RESPONSE_BYTES)
        return [ uri, response.last ] if document_body?(response)
        return unless response.is_a?(String)

        uri = parse_uri(URI.join(uri, response).to_s)
      end

      nil
    end

    def download_image(image_url)
      return if image_url.blank?

      uri = parse_uri(image_url)

      MAX_REDIRECTS.times do
        response = response_for(uri, accept: "image/avif,image/webp,image/png,image/jpeg,image/*", max_bytes: MAX_IMAGE_BYTES)
        return image_from(uri, response.last, response.first) if image_body?(response)
        return unless response.is_a?(String)

        uri = parse_uri(URI.join(uri, response).to_s)
      end

      nil
    rescue UnsafeUrl, UnsupportedResponse
      nil
    end

    def parse_uri(value)
      uri = URI.parse(value)
      return uri if uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.blank? && [ 80, 443 ].include?(uri.port)

      raise UnsafeUrl
    rescue URI::InvalidURIError
      raise UnsafeUrl
    end

    def response_for(uri, accept:, max_bytes:)
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.ipaddr = resolved_public_ip(uri.host)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Get.new(uri.request_uri, {
        "Accept" => accept,
        "Accept-Encoding" => "identity",
        "User-Agent" => USER_AGENT
      })

      http.start do |client|
        client.request(request) do |response|
          return response["location"] if response.is_a?(Net::HTTPRedirection) && response["location"].present?
          return unless response.is_a?(Net::HTTPSuccess)
          return if response.content_length && response.content_length > max_bytes

          body = +""
          response.read_body do |chunk|
            body << chunk
            raise ResponseTooLarge if body.bytesize > max_bytes
          end
          [ response, body ]
        end
      end
    end

    def document_body?(response)
      response.is_a?(Array) && response.first.content_type.to_s.start_with?("text/html")
    end

    def image_body?(response)
      response.is_a?(Array) && image_content_type(response.last, response.first.content_type)
    end

    def image_from(uri, body, response)
      content_type = image_content_type(body, response.content_type)
      return unless content_type

      io = StringIO.new(body)
      io.binmode

      Image.new(io:, filename: filename_for(uri, content_type), content_type:)
    end

    def image_content_type(body, declared_type)
      detected = Marcel::MimeType.for(StringIO.new(body), declared_type: declared_type.to_s)
      detected if ALLOWED_IMAGE_TYPES.include?(detected)
    end

    def filename_for(uri, content_type)
      name = File.basename(uri.path.to_s)
      return name if name.match?(IMAGE_FILENAME)

      "preview.#{IMAGE_EXTENSIONS.fetch(content_type, "img")}"
    end

    def absolute_url(base_uri, value)
      return if value.blank?

      parse_uri(URI.join(base_uri, value).to_s).to_s
    rescue UnsafeUrl, URI::InvalidURIError
      nil
    end

    def youtube_thumbnail_url(*uris)
      video_id = youtube_video_id(*uris)
      return unless video_id

      "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg"
    end

    def youtube_source_name(*uris)
      "YouTube" if youtube_video_id(*uris)
    end

    def youtube_video_id(*uris)
      uris.compact.each do |uri|
        uri = uri.is_a?(URI) ? uri : parse_uri(uri)
        host = uri.host&.downcase
        next unless YOUTUBE_HOSTS.include?(host)

        candidate = if host.delete_prefix("www.") == "youtu.be"
          uri.path.delete_prefix("/").split("/").first
        else
          query_value(uri, "v").presence || uri.path[%r{\A/(?:shorts|embed|live)/([^/]+)}, 1]
        end

        return candidate if candidate&.match?(YOUTUBE_VIDEO_ID)
      end

      nil
    end

    def query_value(uri, key)
      URI.decode_www_form(uri.query.to_s).assoc(key)&.last
    end

    def resolved_public_ip(host)
      address = Addrinfo.getaddrinfo(host, nil, :UNSPEC, :STREAM).map(&:ip_address).find { |ip| public_ip?(ip) }
      raise UnsafeUrl unless address

      address
    rescue SocketError
      raise UnsafeUrl
    end

    def public_ip?(address)
      ip = IPAddr.new(address)
      return public_ip?(ip.native.to_s) if ip.ipv4_mapped?

      !ip.loopback? && !ip.private? && !ip.link_local? && !multicast?(ip) && !unspecified?(ip)
    rescue IPAddr::InvalidAddressError
      false
    end

    def multicast?(ip)
      if ip.respond_to?(:multicast?)
        ip.multicast?
      elsif ip.ipv4?
        IPAddr.new("224.0.0.0/4").include?(ip)
      else
        IPAddr.new("ff00::/8").include?(ip)
      end
    end

    def unspecified?(ip)
      if ip.respond_to?(:unspecified?)
        ip.unspecified?
      else
        ip == IPAddr.new(ip.ipv4? ? "0.0.0.0" : "::")
      end
    end
end
