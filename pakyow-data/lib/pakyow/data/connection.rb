# frozen_string_literal: true

require "uri"
require "forwardable"

require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"
require "pakyow/support/indifferentize"
require "pakyow/support/inflector"

module Pakyow
  module Data
    class Connection
      extend Forwardable
      def_delegators :@adapter, :dataset_for_source, :transaction

      attr_reader :type, :name, :opts, :adapter, :failure

      extend Support::DeepFreeze
      insulate :logger, :adapter

      def initialize(type:, name:, string: nil, opts: nil, logger: nil)
        @type, @name, @logger, @failure = type, name, logger, nil

        @opts = self.class.adapter(type).build_opts(
          opts.is_a?(Hash) ? opts : self.class.parse_connection_string(string)
        )

        @adapter = self.class.adapter(@type).new(@opts, logger: @logger)
      rescue ConnectionError, MissingAdapter => error
        error.context = self
        @failure = error
      end

      def connected?
        !failed? && @adapter.connected?
      end

      def failed?
        !@failure.nil?
      end

      def auto_migrate?
        migratable? && @adapter.auto_migratable?
      end

      def migratable?
        connected? && @adapter.migratable?
      end

      def connect
        @adapter.connect
      end

      def disconnect
        @adapter.disconnect
      end

      def types
        if @adapter.class.const_defined?("TYPES")
          @adapter.class.types_for_adapter(adapter.connection.opts[:adapter])
        else
          {}
        end
      end

      extend Support::ClassState
      class_state :adapter_types, default: []

      using Support::Indifferentize

      class << self
        def parse_connection_string(connection_string)
          uri = URI(connection_string)

          {
            adapter: uri.scheme,
            path: uri.path,
            host: uri.host,
            port: uri.port,
            user: uri.user,
            password: uri.password
          }.merge(
            CGI::parse(uri.query.to_s).transform_values(&:first).indifferentize
          )
        end

        def register_adapter(type)
          (@adapter_types << type).uniq!
        end

        def adapter(type)
          if @adapter_types.include?(type.to_sym)
            require "pakyow/data/adapters/#{type}"
            Adapters.const_get(Support.inflector.camelize(type))
          else
            raise UnknownAdapter.new_with_message(type: type)
          end
        end
      end
    end
  end
end
