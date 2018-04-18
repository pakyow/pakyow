# frozen_string_literal: true

require "uri"
require "forwardable"

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Data
    class Connection
      extend Forwardable
      def_delegators :@adapter, :dataset_for_source, :connected?, :disconnect,
                     :migratable?, :needs_migration?, :migrate!, :auto_migrate!,
                     :finalize_migration!

      attr_reader :type, :name, :opts

      def initialize(type:, name:, string: nil, opts: nil)
        @type, @name = type, name

        @opts = if opts.is_a?(Hash)
          opts
        else
          self.class.parse_connection_string(string)
        end

        if SUPPORTED_CONNECTION_TYPES.include?(type)
          require "pakyow/data/adapters/#{type}"
          @adapter = Adapters.const_get(Support.inflector.classify(type)).new(@opts)
        else
          # TODO: raise nice UnsupportedConnectionType error, telling them what the supported types are
        end
      rescue LoadError => e
        puts e

        # TODO: raise nice MissingConnectionAdapter error, telling them how to proceed
      end

      def connected?
        !@adapter.nil? && @adapter.connected?
      end

      def auto_migrate?
        @adapter.migratable? && @adapter.respond_to?(:auto_migrate!)
      end

      def finalize_migration?
        @adapter.migratable? && @adapter.respond_to?(:finalize_migration!)
      end

      def types
        if @adapter.class.const_defined?("TYPES")
          @adapter.class.const_get("TYPES")
        else
          nil
        end
      end

      class << self
        using Support::Refinements::String::Normalization

        def parse_connection_string(connection_string)
          uri = URI(connection_string)

          {
            adapter: uri.scheme,
            path: String.normalize_path(uri.path)[1..-1],
            host: uri.host,
            user: uri.user,
            password: uri.password
          }
        end
      end
    end
  end
end
