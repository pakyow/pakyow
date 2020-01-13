# frozen_string_literal: true

require "concurrent/array"
require "concurrent/hash"

require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"

require "pakyow/support/configurable/setting"

module Pakyow
  module Support
    module Configurable
      # A group of configurable settings.
      #
      class Config
        using DeepDup

        extend DeepFreeze
        insulate :configurable

        extend Pakyow::Support::Deprecatable

        # @api private
        attr_reader :__settings, :__defaults, :__groups

        def initialize(configurable, name: nil, path: [])
          @configurable, @__name, @__path = configurable, name, path

          @__settings = Concurrent::Hash.new
          @__defaults = Concurrent::Hash.new
          @__groups = Concurrent::Hash.new
          @__deprecations = Concurrent::Array.new
        end

        def initialize_copy(_)
          @__defaults = @__defaults.deep_dup
          @__settings = @__settings.deep_dup
          @__groups = @__groups.deep_dup
          @__deprecations = @__deprecations.deep_dup

          @__settings.each_pair do |key, _|
            define_setting_methods(key)
          end

          @__groups.each_pair do |key, _|
            define_group_methods(key)
          end

          @__deprecations.each do |deprecation|
            define_deprecation deprecation[:target], deprecation[:solution]
          end

          super
        end

        # Define setting `name` with `default`. If a block is given, the default value will be built
        # eagerly the first time the setting is accessed.
        #
        def setting(name, default = default_omitted = true, &block)
          tap do
            name = name.to_sym

            if default_omitted
              default = nil
            end

            unless @__settings.include?(name)
              define_setting_methods(name)
            end

            @__settings[name] = Setting.new(default: default, configurable: @configurable, &block)
          end
        end

        # Define defaults for one or more environments.
        #
        def defaults(*environments, &block)
          environments.each do |environment|
            (@__defaults[environment] ||= Concurrent::Array.new) << block
          end
        end

        # Define a nested configurable.
        #
        def configurable(group, &block)
          group = group.to_sym

          config = Config.new(@configurable, name: group, path: path_to_self)
          config.instance_eval(&block)

          unless @__groups.include?(group)
            define_group_methods(group)
          end

          @__groups[group] = config
        end

        # Configure default values for `environment`.
        #
        def configure_defaults!(environment)
          @__defaults[environment.to_s.to_sym]&.each do |defaults|
            instance_eval(&defaults)
          end

          @__groups.each_pair do |_, group|
            group.configure_defaults!(environment)
          end
        end

        # If value for `setting` is a proc, the block will be evaled in `context`. The return value
        # is the return value of `context`, or the value of the setting if not a proc.
        #
        def eval(setting, context)
          value = public_send(setting)

          if value.is_a?(Proc)
            context.instance_eval(&value)
          else
            value
          end
        end

        # Returns configuration as a hash.
        #
        def to_h
          hash = {}

          @__settings.each_with_object(hash) { |(name, setting), h|
            h[name] = setting.value
          }

          @__groups.each_with_object(hash) { |(name, group), h|
            h[name] = group.to_h
          }

          hash
        end

        def deprecate(target = self, solution: "do not use")
          define_deprecation(target, solution)

          @__deprecations << { target: target, solution: solution }
        end

        private def define_deprecation(target, solution)
          if @__settings.include?(target)
            singleton_class.deprecate(:"#{target}=", solution: solution)
          end

          singleton_class.deprecate(target, solution: solution)
        end

        # @api private
        def update_configurable(configurable)
          @configurable = configurable

          @__settings.values.each do |setting|
            setting.update_configurable(configurable)
          end

          @__groups.values.each do |group|
            group.update_configurable(configurable)
          end
        end

        private def path_to_self
          @__path_to_self ||= (@__path.dup << @__name).compact
        end

        private def deprecated_method_reference(target)
          unless defined?(@deprecated_method_reference)
            configurable_context = case @configurable
            when Class, Module
              @configurable
            else
              @configurable.class
            end

            target = if target.to_s[-1] == "="
              target[0..-2]
            else
              target
            end

            @deprecated_method_reference = ([
              configurable_context.name, "config"
            ].concat(path_to_self) << target).compact.join(".")
          end

          @deprecated_method_reference
        end

        private def find_setting(name)
          @__settings[name.to_sym]
        end

        private def find_group(name)
          @__groups[name.to_sym]
        end

        private def define_setting_methods(name)
          singleton_class.define_method name do |&block|
            if block
              find_setting(name).set(block)
            else
              find_setting(name).value
            end
          end

          singleton_class.define_method :"#{name}=" do |value|
            find_setting(name).set(value)
          end
        end

        private def define_group_methods(name)
          singleton_class.define_method name do
            find_group(name)
          end
        end
      end
    end
  end
end
