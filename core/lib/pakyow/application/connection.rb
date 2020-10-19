# frozen_string_literal: true

require "delegate"

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/support/handleable"
require "pakyow/support/hookable"

module Pakyow
  class Application
    class Connection < SimpleDelegator
      attr_reader :app

      include Support::Hookable
      events :initialize, :dup

      require_relative "connection/behavior/session"
      require_relative "connection/behavior/verifier"
      require_relative "connection/behavior/values"

      include Behavior::Session
      include Behavior::Verifier
      include Behavior::Values

      include Support::Handleable

      require_relative "../connection/behavior/handling"
      include Pakyow::Connection::Behavior::Handling

      using Support::Refinements::String::Normalization

      def initialize(app, connection)
        if app.rescued?
          __initialize(app, connection)
        else
          performing :initialize do
            __initialize(app, connection)
          end
        end
      end

      private def __initialize(app, connection)
        @app = app
        __setobj__(connection)
      end

      def initialize_dup(_)
        performing :dup do
          super
        end
      end

      def path
        unless defined?(@path)
          @path = String.normalize_path(
            __getobj__.path.split(@app.mount_path, 2)[1]
          )
        end

        @path
      end

      def method
        __getobj__.method
      end

      # Triggers `event`, passing any arguments to triggered handlers.
      #
      # Calls connection handlers, then propagates the event to the application.
      #
      def trigger(event, *args, **kwargs)
        super(event, *args, **kwargs) do
          if block_given?
            yield
          else
            @app.trigger(event, *args, **kwargs)
          end
        end

        halt
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end

      # @api private
      def handling_target
        @app
      end

      # @api private
      def self.from_connection(connection, **overrides)
        instance = allocate

        connection.instance_variables.each do |ivar|
          instance.instance_variable_set(ivar, overrides[ivar] || connection.instance_variable_get(ivar))
        end

        instance
      end
    end
  end
end
