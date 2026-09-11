require "ipaddr"

module LinkPreviewHttpHelper
  MINIMAL_PNG = [ "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082" ].pack("H*")

  FakeAddress = Struct.new(:ip_address)

  class FakeHTTP
    def initialize(host, port, *)
      @host = host
      @port = port
    end

    attr_accessor :ipaddr, :use_ssl, :open_timeout, :read_timeout

    def start
      yield self
    end

    def request(http_request)
      responses = Thread.current[:link_preview_http_responses] || {}
      url = "#{use_ssl ? "https" : "http"}://#{@host}#{port_suffix}#{http_request.path}"
      spec = responses.fetch(url) { raise "Unexpected link preview request: #{url}" }
      yield FakeResponse.new(**spec)
    end

    private
      def port_suffix
        default_port = use_ssl ? 443 : 80
        @port.to_i == default_port ? "" : ":#{@port}"
      end
  end

  class FakeResponse
    def initialize(status:, body: "", content_type: nil, location: nil, content_length: nil)
      @status = status
      @body = body
      @content_length = content_length
      @headers = {}
      @headers["location"] = location if location
      @headers["content-type"] = content_type if content_type
    end

    def [](name)
      @headers[name.to_s.downcase]
    end

    def content_type
      self["content-type"]
    end

    def content_length
      @content_length
    end

    def is_a?(klass)
      return @status.between?(300, 399) if klass == Net::HTTPRedirection
      return @status.between?(200, 299) if klass == Net::HTTPSuccess

      super
    end

    def read_body
      yield @body
      @body
    end
  end

  def stub_link_preview_http(responses)
    Thread.current[:link_preview_http_responses] = responses

    Addrinfo.stub(:getaddrinfo, method(:stubbed_preview_addrinfo)) do
      Net::HTTP.stub(:new, ->(host, port, *) { FakeHTTP.new(host, port) }) do
        yield
      end
    end
  ensure
    Thread.current[:link_preview_http_responses] = nil
  end

  def stubbed_preview_addrinfo(host, *)
    ip = IPAddr.new(host)
    [ FakeAddress.new(ip.to_s) ]
  rescue IPAddr::InvalidAddressError
    [ FakeAddress.new("203.0.113.10") ]
  end

  def preview_html(title: "A useful article", description: "A concise summary", site_name: "Example", image_url: nil)
    tags = []
    tags << %(<meta property="og:title" content="#{title}">) if title
    tags << %(<meta property="og:description" content="#{description}">) if description
    tags << %(<meta property="og:site_name" content="#{site_name}">) if site_name
    tags << %(<meta property="og:image" content="#{image_url}">) if image_url

    <<~HTML
      <html>
        <head>
          #{tags.join("\n")}
        </head>
      </html>
    HTML
  end
end
