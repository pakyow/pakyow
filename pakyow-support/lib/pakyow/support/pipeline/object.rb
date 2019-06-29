# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
      # Makes an object passable through a pipeline.
      #
      module Object
        def self.included(base)
          base.prepend Initializer
        end

        def pipelined
          tap do
            @pipelined = true
          end
        end

        def pipelined?
          @pipelined == true
        end

        def halt
          @halted = true
          throw :halt, true
        end

        def halted?
          @halted == true
        end

        module Initializer
          def initialize(*args)
            @pipelined, @halted = false
            super
          end
        end
      end
    end
  end
end
