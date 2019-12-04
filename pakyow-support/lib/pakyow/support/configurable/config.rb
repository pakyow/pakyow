# frozen_string_literal: true

require "concurrent/hash"

require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"

require "pakyow/support/configurable/setting"

module Pakyow
  module Support
    module Configurable
      # @api private
      class Config
        using DeepDup

        extend DeepFreeze
        insulate :configurable

        # @api private
        attr_reader :__settings, :__defaults, :__groups, :__name

        DEFAULT_SOLUTION = "do not use"

        def initialize(configurable, name: nil, path: [], deprecated: false, solution: DEFAULT_SOLUTION)
          @configurable, @__name, @__path, @__deprecated, @__solution = configurable, name, path, deprecated, solution

          @__settings = Concurrent::Hash.new
          @__defaults = Concurrent::Hash.new
          @__groups   = Concurrent::Hash.new
        end

        def initialize_copy(_)
          @__defaults = @__defaults.deep_dup
          @__settings = @__settings.deep_dup
          @__groups   = @__groups.deep_dup

          @__settings.each do |key, _|
            define_setting_methods(key)
          end

          @__groups.each do |key, _|
            define_group_methods(key)
          end

          super
        end

        def setting(name, default = default_omitted = true, &block)
          tap do
            build_setting(name, default, default_omitted, block)
          end
        end

        def deprecated_setting(name, default = default_omitted = true, solution = Setting::DEFAULT_SOLUTION, &block)
          tap do
            build_setting(name, default, default_omitted, block, deprecated: true, solution: solution)
          end
        end

        def defaults(*environments, &block)
          environments.each do |environment|
            (@__defaults[environment] ||= []) << block
          end
        end

        def configurable(group, &block)
          build_configurable(group, block)
        end

        def deprecated_configurable(group, solution = DEFAULT_SOLUTION, &block)
          build_configurable(group, block, deprecated: true, solution: solution)
        end

        def configure_defaults!(configured_environment)
          @__defaults[configured_environment.to_s.to_sym].to_a.each do |defaults|
            instance_eval(&defaults)
          end

          @__groups.values.each do |group|
            group.configure_defaults!(configured_environment)
          end
        end

        def update_configurable(configurable)
          @configurable = configurable

          @__settings.values.each do |setting|
            setting.update_configurable(configurable)
          end

          @__groups.values.each do |group|
            group.update_configurable(configurable)
          end
        end

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

        def eval(setting, context)
          value = public_send(setting)
          if value.is_a?(Proc)
            context.instance_eval(&value)
          else
            value
          end
        end

        private

        def path_to_self
          (@__path.dup << @__name).compact
        end

        def find_setting(name)
          @__settings[name.to_sym]
        end

        def find_group(name)
          @__groups[name.to_sym]
        end

        def define_setting_methods(name)
          singleton_class.define_method name do |&block|
            maybe_report_deprecation

            if block
              find_setting(name).set(block)
            else
              find_setting(name).value
            end
          end

          singleton_class.define_method :"#{name}=" do |value|
            maybe_report_deprecation

            find_setting(name).set(value)
          end
        end

        def define_group_methods(name)
          singleton_class.define_method name do
            find_group(name)
          end
        end

        def names
          unless defined?(@__names)
            @__names = (["config"].concat(@__path) << @__name).freeze
          end

          @__names
        end

        def deprecation_message
          "#{names.join(".")}"
        end

        def maybe_report_deprecation
          if @__deprecated
            Support::Deprecator.global.deprecated deprecation_message, @__solution
          end
        end

        def build_setting(name, default, default_omitted, block, **options)
          name = name.to_sym

          if default_omitted
            default = nil
          end

          unless @__settings.include?(name)
            define_setting_methods(name)
          end

          @__settings[name] = Setting.new(
            name: name,
            path: path_to_self,
            default: default,
            configurable: @configurable,
            **options,
            &block
          )
        end

        def build_configurable(group, block, **options)
          group = group.to_sym

          config = Config.new(
            @configurable,
            name: group,
            path: path_to_self,
            **options
          )

          config.instance_eval(&block)

          unless @__groups.include?(group)
            define_group_methods(group)
          end

          @__groups[group] = config
        end
      end
    end
  end
end
