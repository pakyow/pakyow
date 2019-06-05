# frozen_string_literal: true

require "cgi"
require "securerandom"

require "async/http"
require "async/http/protocol/response"

require "mini_mime"

require "pakyow/support/deep_dup"
require "pakyow/support/hookable"
require "pakyow/support/indifferentize"
require "pakyow/support/inspectable"
require "pakyow/support/pipeline/object"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/logger"

module Pakyow
  # Represents the connection throughout a request/response lifecycle.
  #
  class Connection
    require "pakyow/connection/params"
    require "pakyow/connection/query_parser"
    require "pakyow/connection/statuses"

    using Support::DeepDup
    using Support::Indifferentize
    using Support::Refinements::Array::Ensurable

    include Support::Hookable
    events :finalize

    include Pakyow::Support::Inspectable
    inspectable :method, :params, :cookies, :@status, :@body

    include Support::Pipeline::Object

    attr_reader :id, :timestamp, :logger, :status, :headers, :body

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
      @headers = {}
      @request = request
      @body = Async::HTTP::Body::Buffered.wrap(StringIO.new)
      @params = Pakyow::Connection::Params.new
      @logger = Logger.new(:http, started_at: @timestamp, id: @id, output: Pakyow.global_logger, level: Pakyow.config.logger.level)
      @streams = []
    end

    def request_header?(key)
      @request.headers.include?(normalize_header(key))
    end

    def request_header(key)
      @request.headers[normalize_header(key)]
    end

    def header?(key)
      @headers.key?(normalize_header(key))
    end

    def header(key)
      @headers[normalize_header(key)]
    end

    def set_header(key, value)
      @headers[normalize_header(key)] = value
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
      @request.body
    end

    def parsed_input
      unless instance_variable_defined?(:@parsed_input)
        @parsed_input = nil; @parsed_input = parse_input
      end

      @parsed_input
    end

    # Returns the request method (e.g. `:get`).
    #
    def method
      unless instance_variable_defined?(:@method)
        @method = if request_method == "POST" && params.include?(:_method)
          params[:_method].downcase.to_sym
        else
          request_method.downcase.to_sym
        end
      end

      @method
    end

    def scheme
      if request_header("https").to_s == "on" || request_header("x-forwarded-ssl").to_s == "on"
        "https"
      elsif value = request_header("x-forwarded-scheme")
        value[0]
      elsif value = request_header("x-forwarded-proto")
        value[0]
      else
        @request.scheme
      end
    end

    def authority
      @request.authority
    end

    def host
      unless instance_variable_defined?(:@host)
        parse_authority
      end

      @host
    end

    def port
      unless instance_variable_defined?(:@port)
        parse_authority
      end

      @port
    end

    def subdomain
      unless instance_variable_defined?(:@subdomain)
        parse_subdomain
      end

      @subdomain
    end

    def path
      unless instance_variable_defined?(:@path)
        parse_path
      end

      @path
    end

    def query
      unless instance_variable_defined?(:@query)
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
      unless instance_variable_defined?(:@endpoint)
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
      unless instance_variable_defined?(:@format)
        parse_format
      end

      @format
    end

    def type
      unless instance_variable_defined?(:@type)
        parse_content_type
      end

      @type
    end
    alias media_type type

    def type_params
      unless instance_variable_defined?(:@parsed_type_params)
        @parsed_type_params = build_type_params
      end

      @parsed_type_params
    end
    alias media_type_params type_params

    def secure?
      scheme == "https"
    end

    # Returns an indifferentized params hash.
    #
    def params
      unless instance_variable_defined?(:@built_params)
        build_params
      end

      @params
    end

    def cookies
      unless instance_variable_defined?(:@cookies)
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
      if mime = MiniMime.lookup_by_extension(format.to_s)
        set_header("content-type", mime.content_type)
      end

      @format = format
    end

    def status=(status)
      @status = Statuses.code(status)
    end

    def body=(body)
      @body = if body.is_a?(Async::HTTP::Body)
        body
      else
        Async::HTTP::Body::Buffered.wrap(body)
      end
    end

    def write(content)
      @body.write(content)
    end
    alias << write

    def close
      @body.close
    end

    def stream(length = nil)
      unless streaming?
        @body = Async::HTTP::Body::Writable.new(length)
      end

      @streams << Async::Task.current.async { |task|
        Thread.current[:pakyow_logger] = @logger

        begin
          yield self
        rescue => error
          @logger.error(error: error)
        end

        @streams.delete(task)
      }
    end

    def streaming?
      @streams.any?
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
            @streams.each(&:stop); @streams = []
          end

          close; @body = Async::HTTP::Body::Buffered.wrap(StringIO.new)
        end

        set_cookies

        if streaming?
          Async::Reactor.run do
            while stream = @streams.shift
              stream.wait
            end

            close
          end
        end

        if instance_variable_defined?(:@response)
          @response
        else
          Async::HTTP::Protocol::Response.new(nil, @status, nil, finalize_headers, @body)
        end
      end
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
      key.to_s.downcase.gsub("_", "-")
    end

    DELETE_COOKIE = {
      value: nil, path: nil, domain: nil, max_age: 0, expires: Time.at(0)
    }.freeze

    def set_cookies
      response_cookies = {}

      # Delete cookies with nil/empty values.
      #
      cookies.delete_if do |_, value|
        value.nil? || value.empty?
      end

      # Normalize cookies.
      #
      cookies.keys.each do |key|
        cookies[key] = normalize_cookie(cookies.delete(key))
      end

      # Set cookies that have new values.
      #
      cookies.reject { |key, cookie|
        cookie[:value] == @request_cookies[key]
      }.each do |key, cookie|
        response_cookies[key] = cookie_config.merge(cookie)
      end

      # Remove cookies.
      #
      (@request_cookies.keys - cookies.keys).each do |key|
        response_cookies[key] = DELETE_COOKIE
      end

      # Build the header value.
      #
      # TODO: protect against cookie values being larger than 4096 bytes
      set_header(
        "set-cookie",
        response_cookies.map { |key, cookie|
          String.new("#{escape(key.to_s)}=#{escape(cookie[:value].to_s)}") << cookie_options(cookie)
        }
      )
    end

    def normalize_cookie(cookie)
      case cookie
      when Hash, Support::IndifferentHash
        cookie
      else
        { value: cookie }
      end
    end

    def cookie_options(cookie)
      String.new.tap do |options|
        options << "; domain=#{cookie[:domain]}" if cookie[:domain]
        options << "; path=#{cookie[:path]}" if cookie[:path]
        options << "; max-age=#{cookie[:max_age]}" if cookie[:max_age]

        if expires = cookie[:expires]
          expires = case expires
          when Integer
            Time.now + expires
          when Date, DateTime, Time
            expires
          else
            nil
          end

          options << "; expires=#{expires.httpdate}" if expires
        end

        options << "; secure" if cookie[:secure]
        options << "; HttpOnly" if cookie[:http_only]

        if same_site = cookie[:same_site]
          same_site = case same_site
          when :lax
            "Lax"
          when :strict
            "Strict"
          else
            nil
          end

          options << "; SameSite=#{same_site}" if same_site
        end
      end
    end

    def cookie_config
      unless instance_variable_defined?(:@cookie_config)
        config = {}
        add_cookie_config(Pakyow.config.cookies, config)
        @cookie_config = config
      end

      @cookie_config
    end

    def add_cookie_config(new_options, config)
      new_options.to_h.each do |key, value|
        if value
          config[key] = value
        end
      end
    end

    def build_params
      @built_params = true
      @params.parse(query.to_s)
      parsed_input
    end

    def build_type_params
      unless instance_variable_defined?(:@type_params)
        parse_content_type
      end

      QueryParser.new.tap { |parser|
        parser.parse(@type_params.to_s)
      }.params.deep_indifferentize
    end

    def parse_input
      if instance_variable_defined?(:@input_parser) && input
        @input_parser.call(input, self).tap do
          input.rewind if input.respond_to?(:rewind)
        end
      else
        nil
      end
    end

    def parse_path
      @path, @query = @request.path.to_s.split("?", 2)
    end

    def parse_authority
      @host, @port = authority.to_s.split(":", 2)
    end

    def parse_subdomain
      @subdomain = if authority.include?(".")
        authority.split(".", 2)[0]
      else
        nil
      end
    end

    def parse_format
      @format = if path.include?(".")
        path.split(".").last.to_sym
      elsif accept = request_header("accept")
        if accept[0] == "*/*"
          :any
        elsif mime_type = MiniMime.lookup_by_content_type(accept[0])&.extension
          mime_type.to_sym
        else
          nil
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

    def finalize_headers
      @headers.each_with_object([]) { |(key, value), headers|
        Array.ensure(value).each do |single_value|
          headers << [key, single_value]
        end
      }
    end
  end
end
