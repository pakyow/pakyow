# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deep_dup"
require "pakyow/support/hookable"
require "pakyow/support/indifferentize"
require "pakyow/support/inspectable"

require "pakyow/support/pipelined/haltable"

module Pakyow
  # Represents the request/response.
  #
  class Connection
    class << self
      # Returns the string representation for a status code.
      #
      # @example
      #   Pakyow::Connection.nice_status(200)
      #   => "OK"
      #
      def nice_status(code)
        Rack::Utils::HTTP_STATUS_CODES[code] || "?"
      end

      # Returns the status code for the symbolized status name.
      #
      # @example
      #   Pakyow::Connection.status_code(:ok)
      #   => 200
      #
      def status_code(code_or_status)
        case code_or_status
        when Symbol
          Rack::Utils::SYMBOL_TO_STATUS_CODE[code_or_status]
        else
          code_or_status.to_i
        end
      end
    end

    using Support::DeepDup
    using Support::Indifferentize

    include Support::Hookable
    events :finalize

    include Pakyow::Support::Inspectable
    inspectable :method, :params, :cookies, :status, :body

    include Support::Pipelined::Haltable

    extend Forwardable
    def_delegators :request, :host, :port, :ip, :user_agent, :base_url, :path, :path_info,
                   :script_name, :url, :session, :env, :logger, :ssl?, :fullpath
    def_delegators :response, :status, :status=, :write, :close, :body=

    attr_reader :app, :request, :response, :values

    # Contains the error object when the connection is in a failed state.
    #
    attr_accessor :error

    def initialize(app, rack_env)
      @app, @request, @response = app, Rack::Request.new(rack_env), Rack::Response.new
      @initial_cookies = cookies.dup
      @values = {}
    end

    # @api private
    def initialize_copy(_)
      super

      @request = @request.dup
      @response = @response.dup
      @values = @values.deep_dup
    end

    def finalize
      performing :finalize do
        set_cookies; @response
      end
    end

    def set?(key)
      @values.key?(key.to_sym)
    end

    def set(key, value)
      @values[key.to_sym] = value
    end

    def get(key)
      @values[key.to_sym]
    end

    def request_header?(key)
      @request.has_header?(key)
    end

    def request_header(key)
      @request.get_header(key)
    end

    def response_header?(key)
      @response.has_header?(key)
    end

    def response_header(key)
      @response.get_header(key)
    end

    def set_response_header(key, value)
      @response.add_header(key, value)
    end

    def delete_response_header(key)
      @response.delete_header(key)
    end

    Endpoint = Struct.new(:path, :params)
    def endpoint
      Endpoint.new(path, params)
    end

    # Returns the request method (e.g. `:get`).
    #
    def method
      @method ||= @request.request_method.downcase.to_sym
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
    def format
      return @format if defined?(@format)

      if @request.path.include?(".")
        @format = @request.path.split(".").last.to_sym
      else
        @format = :html
      end
    end

    # Returns an indifferentized params hash.
    #
    def params
      @params ||= @request.params.deep_indifferentize
    end

    # Returns an indifferentized cookie hash.
    #
    def cookies
      @cookies ||= @request.cookies.indifferentize
    end

    # Sets the Content-Type header based on the format.
    #
    # @example
    #   request.format = :json
    #   request.content_type
    #   => "application/json"
    #
    def format=(format)
      @response["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end

    # Returns the value of the Content-Type header.
    #
    def content_type
      @response["Content-Type"]
    end
    alias type content_type

    private

    def set_cookies
      config = @app.config.cookies

      cookies.each_pair do |name, value|
        # delete the cookie if the value has been set to nil
        @response.delete_cookie(name) if value.nil?

        # cookie is already set with value, ignore
        next if @initial_cookies.include?(name) && @initial_cookies[name] == value

        # set cookie with defaults
        @response.set_cookie(name, path: config.path, expires: Time.now + config.expiry, value: value)
      end

      # delete cookies that were deleted from the request
      (@initial_cookies.keys - cookies.keys).each do |name|
        @response.delete_cookie(name)
      end
    end
  end
end
