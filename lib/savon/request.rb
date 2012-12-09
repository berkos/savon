require "httpi"
require "savon/response"

module Savon
  class Request

    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }

    def initialize(globals, locals)
      @globals = globals
      @locals = locals
      @http = create_http_client
    end

    def call(body)
      @http.body = body  # TODO: implement soap.signature? [dh, 2012-12-09]
      @http.headers["Content-Length"] = body.bytesize.to_s

      log_request @http.url, @http.headers, @http.body
      response = HTTPI.post(@http)
      log_response response.code, response.body

      Response.new(response, @globals, @locals)
    end

    private

    def create_http_client
      http = HTTPI::Request.new
      http.url = @globals.get(:endpoint)

      http.proxy = @globals.get(:proxy) if @globals.proxy?
      http.set_cookies @globals.get(:last_response) if @globals.last_response?

      http.open_timeout = @globals.get(:open_timeout) if @globals.open_timeout?
      http.read_timeout = @globals.get(:read_timeout) if @globals.read_timeout?

      http.headers = @globals.get(:headers) if @globals.headers?
      http.headers["SOAPAction"] ||= %{"#{@locals.get(:soap_action)}"}
      http.headers["Content-Type"] = content_type

      http
    end

    def content_type
      CONTENT_TYPE[@globals.get(:soap_version)] % @globals.get(:encoding)
    end

    def log_request(url, headers, body)
      log "SOAP request: #{url}"
      log headers.map { |key, value| "#{key}: #{value}" }.join(", ")
      log body, :pretty => @globals.get(:pretty_print_xml), :filter => true
    end

    def log_response(code, body)
      log "SOAP response (status #{code}):"
      log body, :pretty => @globals.get(:pretty_print_xml)
    end

    def log(message, options = {})
      @globals.get(:logger).log(message, options)
    end

  end
end
