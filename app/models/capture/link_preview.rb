require "ipaddr"
require "net/http"
require "nokogiri"
require "socket"
require "uri"

class Capture::LinkPreview
  Preview = Data.define(:title, :description, :source_name)

  class UnsafeUrl < StandardError; end
  class UnsupportedResponse < StandardError; end
  class ResponseTooLarge < UnsupportedResponse; end

  MAX_REDIRECTS = 3
  MAX_RESPONSE_BYTES = 1.megabyte
  OPEN_TIMEOUT = 3.seconds
  READ_TIMEOUT = 5.seconds
  USER_AGENT = "Infinity link preview/1.0"

  def self.fetch(source_url)
    new(source_url).fetch
  end

  def self.parse(html)
    document = Nokogiri::HTML5.parse(html)

    Preview.new(
      title: metadata(document, "og:title") || text_at(document, "title"),
      description: metadata(document, "og:description") || metadata(document, "description", attribute: "name"),
      source_name: metadata(document, "og:site_name")
    )
  end

  def initialize(source_url)
    @source_url = source_url
  end

  def fetch
    uri = parse_uri(@source_url)

    MAX_REDIRECTS.times do
      response = response_for(uri)
      return self.class.parse(response) if response.is_a?(String)
      return unless response

      uri = parse_uri(URI.join(uri, response).to_s)
    end

    nil
  end

  private
    def self.metadata(document, property, attribute: "property")
      value = document.at_css(%(meta[#{attribute}="#{property}"]))&.[]("content")
      normalize(value)
    end

    def self.text_at(document, selector)
      normalize(document.at_css(selector)&.text)
    end

    def self.normalize(value)
      value.to_s.squish.presence&.truncate(300)
    end

    def parse_uri(value)
      uri = URI.parse(value)
      return uri if uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.blank? && [ 80, 443 ].include?(uri.port)

      raise UnsafeUrl
    rescue URI::InvalidURIError
      raise UnsafeUrl
    end

    def response_for(uri)
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.ipaddr = resolved_public_ip(uri.host)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Get.new(uri.request_uri, {
        "Accept" => "text/html,application/xhtml+xml",
        "Accept-Encoding" => "identity",
        "User-Agent" => USER_AGENT
      })

      http.start do |client|
        client.request(request) do |response|
          return response["location"] if response.is_a?(Net::HTTPRedirection) && response["location"].present?
          return unless response.is_a?(Net::HTTPSuccess) && response.content_type.to_s.start_with?("text/html")
          return if response.content_length && response.content_length > MAX_RESPONSE_BYTES

          body = +""
          response.read_body do |chunk|
            body << chunk
            raise ResponseTooLarge if body.bytesize > MAX_RESPONSE_BYTES
          end
          body
        end
      end
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

      !ip.loopback? && !ip.private? && !ip.link_local? && !ip.multicast? && !ip.unspecified?
    rescue IPAddr::InvalidAddressError
      false
    end
end
