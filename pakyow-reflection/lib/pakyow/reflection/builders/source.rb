# frozen_string_literal: true

require "pakyow/reflection/builders/base"

module Pakyow
  module Reflection
    module Builders
      # @api private
      class Source < Base
        def build(scope)
          block = Proc.new do
            scope.attributes.each do |attribute|
              unless attributes.key?(attribute.name)
                attribute attribute.name, attribute.type
              end
            end

            scope.children.each do |child_scope|
              unless associations[:has_many].any? { |association|
                                                      association.name == child_scope.plural_name
                                                    } || associations[:has_one].any? { |association|
                                                      association.name == child_scope.name
                                                    }
                has_many child_scope.plural_name, dependent: :delete
              end
            end
          end

          (source_for_scope(scope) || define_source_for_scope(scope)).tap do |source|
            unless source.__source_location
              source.__source_location = block.source_location
            end

            source.class_eval(&block)
          end
        end

        private

        def source_for_scope(scope)
          @app.state(:source).find { |source|
            source.plural_name == scope.plural_name
          }
        end

        def define_source_for_scope(scope)
          connection = if scope.actions.any?
            @app.config.reflection.data.connection
          else
            :memory
          end

          @app.source scope.plural_name, adapter: :sql, connection: connection do
            # intentionally empty
          end
        end
      end
    end
  end
end
