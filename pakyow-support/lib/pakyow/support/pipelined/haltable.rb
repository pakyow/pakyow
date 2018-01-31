# frozen_string_literal: true

module Pakyow
  module Support
    module Pipelined
      # Makes an object haltable.
      #
      module Haltable
        def self.included(base)
          base.prepend Initializer
        end

        def halt
          @halted = true
          throw :halt
        end

        def halted?
          @halted == true
        end

        module Initializer
          def initialize(*args)
            @halted = false
            super
          end
        end
      end
    end
  end
end
