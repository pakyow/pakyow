# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      # Manages {Framework} instances.
      #
      module Frameworks
        extend Support::Extension

        apply_extension do
          setting :loaded_frameworks, []
        end

        class_methods do
          # Includes one or more frameworks into the app class.
          #
          def include_frameworks(*frameworks)
            tap do
              frameworks.each do |framework_name|
                include_framework(framework_name)
              end
            end
          end

          # Includes a framework into the app class.
          #
          def include_framework(framework_name)
            framework_name = framework_name.to_sym
            Pakyow.frameworks.fetch(framework_name).new(self).boot
            (config.loaded_frameworks << framework_name).uniq!
          rescue KeyError => error
            raise UnknownFramework.build(error, framework: framework_name)
          end

          # Returns true if +framework+ is loaded.
          #
          def includes_framework?(framework_name)
            config.loaded_frameworks.include?(framework_name.to_sym)
          end
        end
      end
    end
  end
end
