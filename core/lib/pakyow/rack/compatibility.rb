# frozen_string_literal: true

require "protocol/http/headers"
require "rack/request"

require_relative "../environment"

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
        rack_normalize_header_key_value(key, @request.get_header(rack_normalize_header(key)))
      end

      def request_header?(key)
        @request.has_header?(rack_normalize_header(key))
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

      def rack_normalize_header(key)
        key.to_s.upcase.tr("-", "_")
      end

      def rack_normalize_header_key_value(key, value)
        if value && (policy = header_policy(key))
          policy.new(value.to_s)
        else
          value
        end
      end

      def header_policy(key)
        key = key.to_s.downcase.tr("_", "-")
        if defined?(Protocol::HTTP::Headers::MERGE_POLICY)
          Protocol::HTTP::Headers::MERGE_POLICY[key]
        elsif defined?(Protocol::HTTP::Headers::POLICY)
          Protocol::HTTP::Headers::POLICY[key]
        end
      end
    end
  end
end
