# frozen_string_literal: true

require "pakyow/support/indifferentize"

module Pakyow
  class App
    class Connection
      module Session
        class Base < DelegateClass(Support::IndifferentHash)
          def initialize(connection, options, values = Support::IndifferentHash.new)
            @connection, @options = connection, options
            super(values)
          end

          # Fixes an issue using pp inside a delegator.
          #
          def pp(*args)
            Kernel.pp(*args)
          end
        end
      end
    end
  end
end
