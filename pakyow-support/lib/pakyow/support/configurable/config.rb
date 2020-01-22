# frozen_string_literal: true

require "concurrent/array"
require "concurrent/hash"

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"
require "pakyow/support/makeable"
require "pakyow/support/object_name"

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

        extend Pakyow::Support::ClassState
        class_state :__settings, default: Concurrent::Hash.new, inheritable: true
        class_state :__defaults, default: Concurrent::Hash.new, inheritable: true
        class_state :__groups, default: Concurrent::Hash.new, inheritable: true

        include Pakyow::Support::Hookable
        include Pakyow::Support::Makeable

        after "make" do
          __settings.each_value do |setting|
            setting.update_configurable(__configurable)
          end
        end

        class << self
          attr_reader :object_name

          # @api private
          def __configurable
            @configurable
          end

          # Define setting `name` with `default`. If a block is given, the default value is built
          # and cached the first time the setting is accessed.
          #
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
              &block
            )

            self
          end

          # Define defaults for one or more environments.
          #
          def defaults(*environments, &block)
            environments.each do |environment|
              (__defaults[environment] ||= Concurrent::Array.new) << block
            end
          end

          # Define a nested configurable.
          #
          def configurable(group, &block)
            group = group.to_sym

            config = Config.make(
              ObjectName.build(
                *object_name.parts.reject { |part| part == :config }, group
              ),
              context: self,
              configurable: __configurable
            )

            config.class_eval(&block)

            unless __groups.include?(group)
              define_group_methods(group)
            end

            __groups[group] = config
          end

          # Configure default values for `environment`.
          #
          def configure_defaults!(environment)
            __defaults[environment.to_s.to_sym].to_a.each do |defaults|
              instance_eval(&defaults)
            end

            __groups.each_value do |group|
              group.configure_defaults!(environment)
            end
          end

          def deprecate(target = self, solution: "do not use")
            if @__settings.include?(target)
              super(:"#{target}=", solution: solution)
            end

            super(target, solution: solution)
          end

          private def define_setting_methods(name)
            define_method name do |&block|
              if block
                find_setting(name).set(block)
              else
                find_setting(name).value
              end
            end

            define_method :"#{name}=" do |value|
              find_setting(name).set(value)
            end
          end

          private def define_group_methods(name)
            define_method name do
              find_group(name)
            end
          end

          private def find_setting(name)
            @__settings[name]
          end

          private def find_group(name)
            @__groups[name]
          end
        end

        def initialize(configurable)
          @configurable = configurable
          @__settings = Concurrent::Hash.new
          @__groups = Concurrent::Hash.new
        end

        def initialize_copy(_)
          @__settings = @__settings.deep_dup
          @__groups = @__groups.deep_dup

          super
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
          ensure_state!

          hash = {}

          @__settings.each_pair do |name, setting|
            hash[name] = setting.value
          end

          @__groups.each_pair do |name, group|
            hash[name] = group.to_h
          end

          hash
        end

        def deprecate(target = self, solution: "do not use")
          self.class.deprecate(target, solution: solution)
        end

        def freeze
          ensure_state!

          super
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

          self
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

            path_to_self = self.class.object_name.parts.reject { |part|
              part == :config
            }

            @deprecated_method_reference = ([
              configurable_context.name, "config"
            ].concat(path_to_self) << target).compact.join(".")
          end

          @deprecated_method_reference
        end

        private def find_setting(name)
          @__settings[name] ||= build_setting(name)
        end

        private def find_group(name)
          @__groups[name] ||= self.class.__groups[name].new(@configurable)
        end

        private def build_setting(name)
          setting = self.class.__settings[name]
          unless @configurable.equal?(self.class.__configurable)
            setting = setting.dup.update_configurable(@configurable)
          end

          setting
        end

        private def ensure_state!
          self.class.__settings.each_key do |name|
            find_setting(name)
          end

          self.class.__groups.each_key do |name|
            find_group(name)
          end
        end
      end
    end
  end
end
