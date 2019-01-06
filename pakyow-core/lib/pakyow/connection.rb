# frozen_string_literal: true

require "forwardable"
require "securerandom"

require "pakyow/support/deep_dup"
require "pakyow/support/hookable"
require "pakyow/support/indifferentize"
require "pakyow/support/inspectable"

require "pakyow/support/pipeline/object"

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

    include Support::Pipeline::Object

    extend Forwardable
    def_delegators :request, :host, :port, :ip, :user_agent, :base_url, :path, :path_info,
                   :script_name, :url, :session, :env, :logger, :ssl?, :fullpath
    def_delegators :response, :status, :status=, :write, :close, :body=

    attr_reader :app, :request, :response, :values, :timestamp, :id, :parsed_body

    # Contains the error object when the connection is in a failed state.
    #
    attr_accessor :error

    def initialize(app, rack_env)
      @timestamp, @id = Time.now, SecureRandom.hex(4)
      @app, @request, @response = app, Rack::Request.new(rack_env), Rack::Response.new
      @initial_cookies = cookies.dup
      @parsed_body = nil
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
        if method == :head
          if @response.body.respond_to?(:close)
            @response.body.close
          end

          @response.body = []
        end

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
      @method ||= if @request.post? && params.include?(:_method)
        params[:_method].downcase.to_sym
      else
        @request.request_method.downcase.to_sym
      end
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
    def format
      @format ||= if path.include?(".")
        path.split(".").last.to_sym
      elsif request_header?("ACCEPT")
        if request_header("ACCEPT") == "*/*"
          :any
        elsif mime_type = Rack::Mime::MIME_TYPES.key(request_header("ACCEPT").split(",", 2)[0].strip)
          mime_type[1..-1].to_sym
        else
          nil
        end
      else
        :html
      end
    end

    # Returns an indifferentized params hash.
    #
    def params
      @params ||= build_params
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

    def parsed_body=(parsed)
      @parsed_body = parsed
      @params = nil
    end

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

    def build_params
      params = @request.params
      if @parsed_body.is_a?(Hash)
        params = params.merge(@parsed_body)
      end

      params.deep_indifferentize
    end
  end
end
