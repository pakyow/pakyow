# frozen_string_literal: true

require "concurrent/array"
require "concurrent/hash"

require_relative "../class_state"
require_relative "../deep_dup"
require_relative "../deep_freeze"
require_relative "../deprecatable"
require_relative "../extension"
require_relative "../makeable"
require_relative "../object_name"

require_relative "setting"

require_relative "config/behavior/defining"

module Pakyow
  module Support
    module Configurable
      # A group of configurable settings.
      #
      class Config
        include Behavior::Defining

        using DeepDup

        extend Deprecatable

        extend ClassState
        class_state :__settings, default: Concurrent::Hash.new, inheritable: true
        class_state :__defaults, default: Concurrent::Hash.new, inheritable: true
        class_state :__groups, default: Concurrent::Hash.new, inheritable: true

        include Hookable
        include Makeable

        include DeepFreeze
        insulate :configurable

        before "freeze" do
          ensure_state!
        end

        after "make" do
          __settings.each_value do |setting|
            setting.update_configurable(__configurable)
          end
        end

        class << self
          # @api private
          attr_reader :__configurable

          # Define defaults for one or more environments.
          #
          def defaults(*environments, &block)
            environments.each do |environment|
              (__defaults[environment] ||= Concurrent::Array.new) << block
            end
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

          def envar_prefix
            if object_name.name == :config
              nil
            else
              object_name.parts.map { |part| part.to_s.upcase }.join("__").to_s
            end
          end

          private def find_setting(name)
            @__settings[name]
          end

          private def find_group(name)
            @__groups[name]
          end
        end

        # @api private
        attr_reader :__configurable, :__settings, :__groups

        def initialize(configurable)
          @__configurable = configurable
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

        def object_name
          self.class.object_name
        end

        def envar_prefix
          self.class.envar_prefix
        end

        # @api private
        def update_configurable(configurable)
          @__configurable = configurable

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
            configurable_context = case __configurable
            when Class, Module
              __configurable
            else
              __configurable.class
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
          @__groups[name] ||= self.class.__groups[name].new(__configurable)
        end

        private def build_setting(name)
          setting = self.class.__settings[name]

          unless __configurable.equal?(self.class.__configurable)
            setting = setting.dup.update_configurable(__configurable)
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
