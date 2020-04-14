# frozen_string_literal: true

require "pakyow/support/class_state"

require_relative "../../../reflection/mirror"

module Pakyow
  class Application
    module Behavior
      module Reflection
        module Reflecting
          extend Support::Extension

          class_methods do
            attr_reader :mirror
          end

          apply_extension do
            after "setup", priority: :high do
              @mirror = Pakyow::Reflection::Mirror.new(self)

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

            after "boot" do
              self.class.mirror.endpoints.each do |endpoint|
                endpoint.exposures.each do |exposure|
                  define_children_for_endpoint_context(exposure)
                end
              end

              # Cleanup.
              #
              unless Pakyow.env?(:test)
                self.class.mirror.scopes.each(&:cleanup)
                self.class.mirror.endpoints.each(&:cleanup)
              end
            end
          end

          def mirror
            self.class.mirror
          end

          private

          def define_children_for_endpoint_context(exposure)
            exposure.nodes.each do |exposure_node|
              exposure_node.find_significant_nodes(:endpoint).each do |endpoint_node|
                if app_endpoint = endpoints.find(name: endpoint_node.label(:endpoint))
                  app_endpoint.params.each do |param|
                    data.send(exposure.scope.plural_name).source.class.associations.values.flatten.each do |association|
                      association_key_prefix = "#{association.name}_"
                      if param.to_s.start_with?(association_key_prefix)
                        scope = self.class.mirror.scopes.find { |scope|
                          scope.plural_name == association.associated_source_name
                        } || Pakyow::Reflection::Scope.new(association.name)

                        Pakyow::Reflection::Exposure.new(
                          scope: scope,
                          nodes: [endpoint_node],
                          parent: exposure,
                          binding: exposure.binding
                        )
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
