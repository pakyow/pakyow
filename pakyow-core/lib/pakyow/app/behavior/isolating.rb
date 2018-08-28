# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  class App
    module Behavior
      # Helps manage isolated classes for an app.
      #
      module Isolating
        extend Support::Extension

        class_methods do
          # Creates a subclass within the app's namespace.
          #
          # @example
          #   class MyApp < Pakyow::App
          #     isolate Pakyow::Controller do
          #       def self.special_behavior
          #         puts "it works"
          #       end
          #     end
          #   end
          #
          #   MyApp::Controller.special_behavior
          #   => it works
          #
          #   Pakyow::Controller
          #   => NoMethodError (undefined method `special_behavior' for Pakyow::Controller:Class)
          #
          def isolate(class_to_isolate, &block)
            isolated_class_name = Support.inflector.demodulize(class_to_isolate.to_s).to_sym
            const_set(isolated_class_name, Class.new(class_to_isolate))

            isolated(isolated_class_name).tap do |defined_subclass|
              defined_subclass.class_eval(&block) if block_given?
            end
          end

          # Returns true if the class name is isolated.
          #
          def isolated?(class_name)
            const_defined?(class_name)
          end

          # Returns the isolated class, evaluating the block (if provided).
          #
          def isolated(class_name, &block)
            const_get(class_name).tap do |isolated_class|
              if isolated_class && block_given?
                isolated_class.class_eval(&block)
              end
            end
          end
        end

        # Convenience method for +Pakyow::App::subclass+.
        #
        def isolated(*args, &block)
          self.class.isolated(*args, &block)
        end
      end
    end
  end
end
