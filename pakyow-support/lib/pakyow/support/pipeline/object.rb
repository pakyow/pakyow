# frozen_string_literal: true

require "pakyow/support/extension"

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
          throw :reject, @__rejected = true
        end

        def rejected?
          @__rejected == true
        end

        def halt
          throw :halt, @__halted = true
        end

        def halted?
          @__halted == true
        end
      end
    end
  end
end
