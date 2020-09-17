# frozen_string_literal: true

require_relative "../extension"
require_relative "../system"

module Pakyow
  module Support
    module Pipeline
      # Makes an object passable through a pipeline.
      #
      module Object
        extend Support::Extension

        prepend_methods do
          if System.ruby_version < "2.7.0"
            def initialize(*)
              __common_pipeline_object_initialize; super
            end
          else
            def initialize(*, **)
              __common_pipeline_object_initialize; super
            end
          end

          private def __common_pipeline_object_initialize
            @__halted = @__rejected = false
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
