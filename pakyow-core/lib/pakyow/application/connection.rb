# frozen_string_literal: true

require "delegate"

require "pakyow/support/hookable"

module Pakyow
  class Application
    class Connection < SimpleDelegator
      attr_reader :app

      include Support::Hookable
      events :initialize, :dup

      require "pakyow/application/connection/behavior/session"
      require "pakyow/application/connection/behavior/verifier"
      require "pakyow/application/connection/behavior/values"

      include Behavior::Session
      include Behavior::Verifier
      include Behavior::Values

      def initialize(app, connection)
        performing :initialize do
          @app = app; __setobj__(connection)
        end
      end

      def initialize_dup(_)
        performing :dup do
          super
        end
      end

      def method
        __getobj__.method
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
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
