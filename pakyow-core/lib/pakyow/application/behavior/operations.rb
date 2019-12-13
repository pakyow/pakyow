# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/operation"

module Pakyow
  class Application
    module Behavior
      # Adds support for operations.
      #
      module Operations
        class Lookup
          def initialize(operations:, app:)
            operations.each do |operation|
              define_singleton_method operation.object_name.name do |values = {}, &block|
                (block ? Class.new(operation, &block) : operation).new(app: app, **values).perform
              end
            end
          end
        end

        extend Support::Extension

        apply_extension do
          on "load" do
            load_aspect(:operations)
          end

          attr_reader :operations
          after "initialize" do
            @operations = Lookup.new(operations: state(:operation), app: self)
          end
        end

        class_methods do
          # Define operations as stateful when an app is defined.
          #
          # @api private
          def make(*)
            super.tap do |new_class|
              new_class.stateful :operation, Operation
            end
          end
        end
      end
    end
  end
end
