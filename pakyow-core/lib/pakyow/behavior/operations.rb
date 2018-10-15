# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/operation"

module Pakyow
  module Behavior
    # Adds support for operations.
    #
    module Operations
      class Lookup
        def initialize(operations)
          operations.each do |operation|
            define_singleton_method operation.__object_name.name do |values = {}|
              operation.new(values).perform
            end
          end
        end
      end

      extend Support::Extension

      apply_extension do
        before :load do
          load_aspect(:operations)
        end

        attr_reader :operations
        after :initialize do
          @operations = Lookup.new(state(:operation))
        end
      end

      class_methods do
        # Define operations as stateful when an app is defined.
        #
        def make(*)
          super.tap do |new_class|
            new_class.stateful :operation, Operation
          end
        end
      end
    end
  end
end
