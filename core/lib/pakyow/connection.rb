# frozen_string_literal: true

require "cgi"
require "securerandom"

require "core/async"

require "async/http"
require "async/http/protocol/response"

require "protocol/http/body/rewindable"

require "mini_mime"

require "pakyow/support/deep_dup"
require "pakyow/support/handleable"
require "pakyow/support/hookable"
require "pakyow/support/indifferentize"
require "pakyow/support/inspectable"
require "pakyow/support/pipeline/object"

require "pakyow/support/core_refinements/array/ensurable"

require_relative "logger"

module Pakyow
  # Represents the connection throughout a request/response lifecycle.
  #
  class Connection
    require_relative "connection/headers"
    require_relative "connection/params"
    require_relative "connection/query_parser"
    require_relative "connection/statuses"

    include Is::Async

    using Support::DeepDup
    using Support::Indifferentize
    using Support::Refinements::Array::Ensurable

    include Support::Hookable
    events :finalize

    include Pakyow::Support::Inspectable
    inspectable :method, :params, :cookies, :@status, :@body

    include Support::Pipeline::Object

    include Support::Handleable

    require_relative "connection/behavior/handling"
    include Behavior::Handling

    attr_reader :id, :timestamp, :logger, :status, :headers, :body

    attr_writer :body

    # Contains the error object when the connection is in a failed state.
    #
    attr_reader :error

    # @api private
    attr_writer :error, :input_parser
    # @api private
    attr_reader :request

    Endpoint = Struct.new(:path, :params)

    def initialize(request)
      @id = SecureRandom.hex(4)
      @timestamp = Time.now
      @status = 200
      @headers = Headers.new
      @request = request
      @body = Async::HTTP::Body::Buffered.wrap(StringIO.new)
      @__original_body = @body
      @params = Pakyow::Connection::Params.new
      @streams = []
      @subdomain_by_tld_length = {}
      @subdomains_by_tld_length = {}

      @__logger = Logger.new(
        :http,
        started_at: @timestamp,
        id: @id,
        output: Pakyow.output,
        level: Pakyow.config.logger.level
      )

      Pakyow.logger.set(@__logger)

      # Always log through the thread-local logger. The thread local gives us a thread-safe way to
      # do things like silencing, so it's preferred over using the connection logger directly.
      #
      @logger = Pakyow.logger
    end

    def request_header?(key)
      @request.headers.include?(normalize_header(key))
    end

    def request_header(key)
      @request.headers[normalize_header(key)]
    end

    def header?(key)
      @headers.include?(normalize_header(key))
    end

    def header(key)
      @headers[normalize_header(key)]
    end

    def set_header(key, value)
      @headers[normalize_header(key)] = normalize_header_value(value)
    end

    def set_headers(headers)
      headers.each do |key, value|
        set_header(normalize_header(key), value)
      end
    end

    def delete_header(key)
      @headers.delete(normalize_header(key))
    end

    def input
      @__input ||= @request.body
    end

    # @api private
    def wrap_input
      if @request.body
        @__input = yield(@request.body)
      end
    end

    def parsed_input
      if should_parse_input?
        parse_input
      end

      @parsed_input
    end

    # Returns the request method (e.g. `:get`).
    #
    def method
      unless defined?(@method)
        @method = if request_method == "POST" && params.include?(:"pw-http-method")
          params[:"pw-http-method"].downcase.to_sym
        else
          request_method.downcase.to_sym
        end
      end

      @method
    end

    def scheme
      if request_header("https").to_s == "on" || request_header("x-forwarded-ssl").to_s == "on"
        "https"
      elsif (value = request_header("x-forwarded-scheme"))
        value[0]
      elsif (value = request_header("x-forwarded-proto"))
        value[0]
      else
        @request.scheme
      end
    end

    def authority
      @request.authority
    end

    def host
      unless defined?(@host)
        parse_authority
      end

      @host
    end

    def port
      unless defined?(@port)
        parse_authority
      end

      @port
    end

    def subdomain(tld_length = 1)
      unless @subdomain_by_tld_length.include?(tld_length)
        parse_subdomain(tld_length)
      end

      @subdomain_by_tld_length[tld_length]
    end

    def subdomains(tld_length = 1)
      unless @subdomains_by_tld_length.include?(tld_length)
        parse_subdomains(tld_length)
      end

      @subdomains_by_tld_length[tld_length]
    end

    def path
      unless defined?(@path)
        parse_path
      end

      @path
    end

    def query
      unless defined?(@query)
        parse_path
      end

      @query
    end

    def fullpath
      @request.path
    end

    def ip
      request_header("x-forwarded-for").to_a.first || @request.remote_address.ip_address
    end

    def endpoint
      unless defined?(@endpoint)
        @endpoint = Endpoint.new(path, params).freeze
      end

      @endpoint
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
    def format
      unless defined?(@format)
        parse_format
      end

      @format
    end

    def type
      unless defined?(@type)
        parse_content_type
      end

      @type
    end
    alias_method :media_type, :type

    def type_params
      unless defined?(@parsed_type_params)
        @parsed_type_params = build_type_params
      end

      @parsed_type_params
    end
    alias_method :media_type_params, :type_params

    def secure?
      scheme == "https"
    end

    # Returns an indifferentized params hash.
    #
    def params
      unless defined?(@built_params)
        build_params
      end

      @params
    end

    def cookies
      unless defined?(@cookies)
        parse_cookies
      end

      @cookies
    end

    # Sets the Content-Type header based on the format.
    #
    # @example
    #   request.format = :json
    #   request.content_type
    #   => "application/json"
    #
    def format=(format)
      if (mime = MiniMime.lookup_by_extension(format.to_s))
        set_header("content-type", mime.content_type)
      end

      @format = format
    end

    def status=(status)
      @status = Statuses.code(status)
    end

    def write(content)
      @body.write(content)
    end
    alias_method :<<, :write

    def close
      @body.close
    end

    def stream(length = nil)
      unless streaming?
        @body = Async::HTTP::Body::Writable.new(length)
      end

      @streams << async {
        begin
          yield self
        rescue => error
          @logger.error(error: error)
        end
      }
    end

    def streaming?
      @streams.any?(&:pending?)
    end

    def async
      super do
        Pakyow.logger.set(@__logger)

        yield if block_given?
      end
    end

    def sleep(seconds)
      Async::Task.current.sleep(seconds)
    end

    def hijack?
      @request.hijack?
    end

    def hijack!
      @request.hijack!
    end

    def finalize
      performing :finalize do
        if request_method == "HEAD"
          if streaming?
            while (stream = @streams.shift)
              stream.cancel
            end
          end
        end

        set_cookies

        if streaming?
          await do
            while (stream = @streams.shift)
              stream.wait
            end

            close
          end
        end

        if defined?(@response)
          @response
        else
          Async::HTTP::Protocol::Response[@status, @headers, @body]
        end
      end
    end

    # Triggers `event`, passing any arguments to triggered handlers.
    #
    # Calls connection handlers, then propagates the event to the environment.
    #
    def trigger(event, *args, **kwargs)
      super(event, *args, **kwargs) do
        if block_given?
          yield
        else
          Pakyow.trigger(event, *args, **kwargs)
        end
      end

      halt
    end

    # @api private
    def handling_target
      Pakyow
    end

    # @api private
    def request_method
      @request.method
    end

    # @api private
    def request_path
      @request.path
    end

    # @api private
    def update_request_cookie(key, value)
      if @request_cookies.key?(key)
        @request_cookies[key] = value
      end
    end

    private

    def normalize_header(key)
      key.to_s.downcase.tr("_", "-")
    end

    def normalize_header_value(value)
      case value
      when Array
        value.map(&:to_s)
      else
        value.to_s
      end
    end

    DELETE_COOKIE = {
      value: nil, path: nil, domain: nil, max_age: 0, expires: Time.at(0)
    }.freeze

    def set_cookies
      response_cookies = {}

      # Delete cookies with nil/empty values.
      #
      cookies.delete_if do |_key, value|
        value.nil? || value.empty?
      end

      # Normalize cookies.
      #
      cookies.each_key do |key|
        cookies[key] = normalize_cookie(cookies[key])
      end

      # Set cookies that have new values.
      #
      cookies.each_pair do |key, cookie|
        unless cookie[:value] == @request_cookies[key]
          response_cookies[key] = cookie_config.merge(cookie)
        end
      end

      # Remove cookies.
      #
      @request_cookies.each_key do |key|
        unless cookies.include?(key)
          response_cookies[key] = DELETE_COOKIE
        end
      end

      # Build the header value.
      #
      # TODO: protect against cookie values being larger than 4096 bytes
      #
      response_cookies.each_pair do |key, cookie|
        set_header("set-cookie", escape(key.to_s) << "=" << escape(cookie[:value].to_s) << serialize_cookie(cookie))
      end
    end

    def normalize_cookie(cookie)
      case cookie
      when Hash, Support::IndifferentHash
        cookie
      else
        {value: cookie}
      end
    end

    def serialize_cookie(cookie)
      serialized = +""

      serialized << "; domain=#{cookie[:domain]}" if cookie[:domain]
      serialized << "; path=#{cookie[:path]}" if cookie[:path]
      serialized << "; max-age=#{cookie[:max_age]}" if cookie[:max_age]

      expires_value = cookie[:expires]
      expires = case expires_value
      when Integer
        Time.now + expires_value
      when Date, DateTime, Time
        expires_value
      end

      serialized << "; expires=#{expires.httpdate}" if expires

      serialized << "; Secure" if cookie[:secure]
      serialized << "; HttpOnly" if cookie[:http_only]

      same_site = case cookie[:same_site].to_s
      when "lax"
        "Lax"
      when "strict"
        "Strict"
      end

      serialized << "; SameSite=#{same_site}" if same_site

      serialized
    end

    def cookie_config
      unless defined?(@cookie_config)
        @cookie_config = Pakyow.config.cookies.to_h
      end

      @cookie_config
    end

    def build_params
      @built_params = true
      @params.parse(query.to_s)
      parse_input if should_parse_input?
    end

    def build_type_params
      unless defined?(@type_params)
        parse_content_type
      end

      parser = QueryParser.new
      parser.parse(@type_params.to_s)
      parser.params.deep_indifferentize
    end

    def parse_input
      @parsed_input = if defined?(@input_parser) && input
        @__parsing_input = true

        if @input_parser[:rewindable]
          @__input = Async::HTTP::Body::Rewindable.new(input)
        end

        parser = @input_parser[:block].call(input, self)

        if input.respond_to?(:rewind)
          input.rewind
        end

        @__did_parse_input = true
        parser
      end
    end

    def should_parse_input?
      !defined?(@__did_parse_input) && !defined?(@__parsing_input)
    end

    def parse_path
      @path, @query = @request.path.to_s.split("?", 2)
    end

    def parse_authority
      @host, @port = authority.to_s.split(":", 2)
    end

    def parse_subdomain(tld_length)
      @subdomain_by_tld_length[tld_length] = if subdomains(tld_length).any?
        subdomains(tld_length).join(".")
      end
    end

    def parse_subdomains(tld_length)
      @subdomains_by_tld_length[tld_length] = if authority.include?(".")
        authority.split(".")[0..-(2 + tld_length)]
      else
        []
      end
    end

    def parse_format
      @format = if path.include?(".")
        path.split(".").last.to_sym
      elsif (accept = request_header("accept"))
        if accept[0] == "*/*"
          :any
        elsif (mime_type = MiniMime.lookup_by_content_type(accept[0])&.extension)
          mime_type.to_sym
        end
      else
        :html
      end
    end

    def parse_content_type
      @type, @type_params = request_header("content-type").to_s.split(";", 2).map(&:strip)
    end

    def parse_cookies
      @cookies = parse_cookie_header
      @request_cookies = @cookies.dup
    end

    def parse_cookie_header
      request_header("cookie").to_a.each_with_object(QueryParser.new) { |line, cookies|
        cookies.parse(line)
      }.params.deep_indifferentize
    end

    def unescape(string)
      CGI.unescape(string)
    end

    def escape(string)
      CGI.escape(string)
    end
  end
end
