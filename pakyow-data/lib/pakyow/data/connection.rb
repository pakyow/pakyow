# frozen_string_literal: true

require "uri"
require "forwardable"

require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"
require "pakyow/support/inflector"

module Pakyow
  module Data
    class Connection
      extend Forwardable
      def_delegators :@adapter, :dataset_for_source, :disconnect, :transaction, :migratable?

      attr_reader :type, :name, :opts, :adapter

      extend Support::DeepFreeze
      unfreezable :logger

      def initialize(type:, name:, string: nil, opts: nil, logger: nil)
        @type, @name, @logger = type, name, logger

        @opts = if opts.is_a?(Hash)
          opts
        else
          self.class.adapter(type).build_opts(
            self.class.parse_connection_string(string)
          )
        end

        @adapter = self.class.adapter(type).new(@opts, logger: logger)
      rescue LoadError => e
        puts e

        # TODO: raise nice MissingConnectionAdapter error, telling them how to proceed
      end

      def connected?
        !@adapter.nil? && @adapter.connected?
      end

      def auto_migrate?
        @adapter.migratable? && @adapter.auto_migratable?
      end

      def types
        if @adapter.class.const_defined?("TYPES")
          @adapter.class.types_for_adapter(adapter.connection.opts[:adapter])
        else
          nil
        end
      end

      extend Support::ClassState
      class_state :adapter_types, default: []

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
          }
        end

        def register_adapter(type)
          (@adapter_types << type).uniq!
        end

        def adapter(type)
          if @adapter_types.include?(type.to_sym)
            begin
              adapter_path = "pakyow/data/adapters/#{type}"
              require adapter_path
              Adapters.const_get(Support.inflector.camelize(type))
            rescue LoadError
              # TODO: present a nicer message here that tells the user how to resolve
              Pakyow.logger.error "Couldn't find a data adapter to load at `#{adapter_path}`"
            end
          else
            # TODO: present a nicer message here that includes a list of known adapters
            Pakyow.logger.error "`#{type}` is not a known adapter"
          end
        end
      end
    end
  end
end
