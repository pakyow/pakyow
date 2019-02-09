# frozen_string_literal: true

require "delegate"

require "pakyow/support/hookable"

module Pakyow
  class App
    class Connection < SimpleDelegator
      attr_reader :app

      include Support::Hookable
      events :initialize, :dup

      require "pakyow/app/connection/behavior/session"
      require "pakyow/app/connection/behavior/verifier"
      require "pakyow/app/connection/behavior/values"

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
    end
  end
end
