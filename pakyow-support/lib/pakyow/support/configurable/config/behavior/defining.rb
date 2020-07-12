# frozen_string_literal: true

require_relative "../../../deep_dup"
require_relative "../../../extension"

module Pakyow
  module Support
    module Configurable
      class Config
        module Behavior
          # Behavior for defining configuration settings and groups.
          #
          # @api public
          module Defining
            extend Extension

            using DeepDup

            class_methods do
              # @api private
              def method_definer
                :define_method
              end

              # @api private
              def configurable_context
                self
              end

              # @api private
              def finalize_group(group)
                group
              end
            end

            # @api private
            def method_definer
              :define_singleton_method
            end

            # @api private
            def configurable_context
              self.class
            end

            # @api private
            def finalize_group(group)
              group.new(__configurable)
            end

            common_methods do
              # Define setting `name` with `default`. If a block is given, the default value is
              # built and cached the first time the setting is accessed.
              #
              # @api public
              def setting(name, default = default_omitted = true, &block)
                name = name.to_sym

                if default_omitted
                  default = nil
                end

                unless __settings.include?(name)
                  define_setting_methods(name)
                end

                __settings[name] = Setting.new(
                  name: name,
                  default: default.deep_dup,
                  configurable: __configurable,
                  envar_prefix: envar_prefix,
                  &block
                )

                self
              end

              # Define a nested configurable group.
              #
              # @api public
              def configurable(group, &block)
                group = group.to_sym

                config = Config.make(
                  ObjectName.build(
                    *object_name.parts.reject { |part| part == :config }, group
                  ),
                  context: configurable_context,
                  __configurable: __configurable
                )

                config.class_eval(&block)

                unless __groups.include?(group)
                  define_group_methods(group)
                end

                __groups[group] = finalize_group(config)
              end

              # @api private
              private def define_setting_methods(name)
                send(method_definer, name) do |&block|
                  if block
                    find_setting(name).set(block)
                  else
                    find_setting(name).value
                  end
                end

                send(method_definer, :"#{name}=") do |value|
                  find_setting(name).set(value)
                end
              end

              # @api private
              private def define_group_methods(name)
                send(method_definer, name) do
                  find_group(name)
                end
              end
            end
          end
        end
      end
    end
  end
end
