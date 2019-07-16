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
            @__pipelined = true
          end
        end

        def pipelined?
          @__pipelined == true
        end

        def halt
          @__halted = true
          throw :halt, true
        end

        def halted?
          @__halted == true
        end

        module Initializer
          def initialize(*args)
            @__halted = false
            @__pipelined = false
            super
          end
        end
      end
    end
  end
end
