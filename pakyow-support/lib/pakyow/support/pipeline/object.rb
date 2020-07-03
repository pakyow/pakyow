# frozen_string_literal: true

require_relative "../extension"

module Pakyow
  module Support
    module Pipeline
      # Makes an object passable through a pipeline.
      #
      module Object
        extend Support::Extension

        prepend_methods do
          def initialize(*)
            @__halted = @__rejected = false

            super
          end
        end

        def reject
          @__rejected = true
          throw :reject, self
        end

        def rejected?
          @__rejected == true
        end

        def halt
          @__halted = true
          throw :halt, self
        end

        def halted?
          @__halted == true
        end
      end
    end
  end
end
