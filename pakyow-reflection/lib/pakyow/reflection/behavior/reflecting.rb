# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/reflection/mirror"

module Pakyow
  module Reflection
    module Behavior
      module Reflecting
        extend Support::Extension

        apply_extension do
          after "initialize", priority: :high do
            mirror = Mirror.new(self)

            builders = config.reflection.builders.values.map { |builder|
              builder.new(self, mirror.scopes)
            }

            mirror.scopes.each do |scope|
              builders.each do |builder|
                builder.build(scope)
              end
            end
          end
        end
      end
    end
  end
end
