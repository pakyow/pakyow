# frozen_string_literal: true

require "protocol/http/headers"
require "rack/request"

require "pakyow/environment"

module Pakyow
  module Rack
    class Connection < ::Pakyow::Connection
      def initialize(rack_env)
        super(::Rack::Request.new(rack_env))
      end

      def query
        @request.query_string
      end

      def fullpath
        @request.fullpath
      end

      def request_header(key)
        normalize_header_key_value(key, @request.get_header(normalize_header(key)))
      end

      def request_header?(key)
        @request.has_header?(normalize_header(key))
      end

      def ip
        @request.ip
      end

      def hijack?
        @request.env["rack.hijack?"]
      end

      def hijack!
        @request.env["rack.hijack"].call
      end

      # @api private
      def request_method
        @request.request_method
      end

      # @api private
      def request_path
        @request.fullpath
      end

      private

      def normalize_header(key)
        key.to_s.upcase.gsub("-", "_")
      end

      def normalize_header_key_value(key, value)
        if value && policy = Protocol::HTTP::Headers::MERGE_POLICY[key.to_s.downcase.gsub("_", "-")]
          policy.new(value.to_s)
        else
          value
        end
      end
    end
  end
end
