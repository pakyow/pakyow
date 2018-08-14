# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  class App
    module Behavior
      # Helps manage subclasses of core objects for an app.
      #
      module Subclassing
        extend Support::Extension

        class_methods do
          # Creates a subclass and defines it in the app's namespace.
          #
          # @example
          #   class MyApp < Pakyow::App
          #     subclass! Pakyow::Controller do
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
          def subclass!(class_to_subclass, &block)
            subclass_name = Support.inflector.demodulize(class_to_subclass.to_s).to_sym

            unless const_defined?(subclass_name)
              const_set(subclass_name, Class.new(class_to_subclass))
            end

            subclass(subclass_name).tap do |defined_subclass|
              defined_subclass.class_eval(&block) if block_given?
            end
          end

          # Returns true if the subclass exists.
          #
          def subclass?(subclass_name)
            const_defined?(subclass_name)
          end

          # Returns the defined subclass, evaluating the block if provided.
          #
          def subclass(subclass_name, &block)
            const_get(subclass_name).tap do |subclass|
              if subclass && block_given?
                subclass.class_eval(&block)
              end
            end
          end
        end

        # Convenience method for +Pakyow::App::subclass+.
        #
        def subclass(*args, &block)
          self.class.subclass(*args, &block)
        end
      end
    end
  end
end
