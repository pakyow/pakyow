# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/reflection/mirror"

module Pakyow
  module Reflection
    module Behavior
      module Reflecting
        extend Support::Extension

        apply_extension do
          attr_reader :mirror

          after "initialize", priority: :high do
            unless Pakyow.env?(:prototype)
              @mirror = Mirror.new(self)

              builders = Hash[
                config.reflection.builders.map { |type, builder|
                  [type, builder.new(self, @mirror.scopes)]
                }
              ]

              # Build the scopes.
              #
              @mirror.scopes.each do |scope|
                builders[:source].build(scope)
              end

              # Build the actions.
              #
              @mirror.scopes.each do |scope|
                builders[:actions].build(scope.actions)
              end

              # Build the endpoints.
              #
              builders[:endpoints].build(@mirror.endpoints)
            end
          end
        end
      end
    end
  end
end
