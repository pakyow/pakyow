# frozen_string_literal: true

require "forwardable"

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
        unfreezable :configurable

        # @api private
        attr_reader :settings

        def initialize(configurable)
          @configurable = configurable

          @settings = Concurrent::Hash.new
          @defaults = Concurrent::Hash.new
          @groups   = Concurrent::Hash.new
        end

        def initialize_copy(_)
          @defaults = @defaults.deep_dup
          @settings = @settings.deep_dup
          @groups   = @groups.deep_dup

          @settings.each do |key, _|
            define_setting_methods(key)
          end

          @groups.each do |key, _|
            define_group_methods(key)
          end

          super
        end

        def setting(name, default = default_omitted = true, &block)
          tap do
            name = name.to_sym
            default = nil if default_omitted

            unless @settings.include?(name)
              define_setting_methods(name)
            end

            @settings[name] = Setting.new(default: default, configurable: @configurable, &block)
          end
        end

        def defaults(environment, &block)
          @defaults[environment] = block
        end

        def configurable(group, &block)
          group = group.to_sym
          config = Config.new(@configurable)
          config.instance_eval(&block)

          unless @groups.include?(group)
            define_group_methods(group)
          end

          @groups[group] = config
        end

        def configure_defaults!(configured_environment)
          if defaults = @defaults[configured_environment.to_s.to_sym]
            instance_eval(&defaults)
          end

          @groups.values.each do |group|
            group.configure_defaults!(configured_environment)
          end
        end

        def update_configurable(configurable)
          @configurable = configurable

          @settings.values.each do |setting|
            setting.update_configurable(configurable)
          end

          @groups.values.each do |group|
            group.update_configurable(configurable)
          end
        end

        def to_h
          hash = {}

          @settings.each_with_object(hash) { |(name, setting), h|
            h[name] = setting.value
          }

          @groups.each_with_object(hash) { |(name, group), h|
            h[name] = group.to_h
          }

          hash
        end

        private

        def find_setting(name)
          @settings[name.to_sym]
        end

        def find_group(name)
          @groups[name.to_sym]
        end

        def define_setting_methods(name)
          singleton_class.define_method name do
            find_setting(name).value
          end

          singleton_class.define_method :"#{name}=" do |value|
            find_setting(name).set(value)
          end
        end

        def define_group_methods(name)
          singleton_class.define_method name do
            find_group(name)
          end
        end
      end
    end
  end
end
