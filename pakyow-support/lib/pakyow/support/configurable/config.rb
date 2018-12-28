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
          @settings = @settings.deep_dup
          @defaults = @defaults.deep_dup
          @groups   = @groups.deep_dup
          super
        end

        def setting(name, default = default_omitted = true, &block)
          tap do
            default = nil if default_omitted
            @settings[name.to_sym] = Setting.new(
              default: default,
              configurable: @configurable,
              &block
            )
          end
        end

        def defaults(environment, &block)
          @defaults[environment] = block
        end

        def configurable(group, &block)
          config = Config.new(@configurable)
          config.instance_eval(&block)
          @groups[group.to_sym] = config
        end

        def method_missing(method_name, value = nil)
          if setter?(method_name) && setting = find_setting(method_name[0..-2])
            setting.set(value)
          elsif setting = find_setting(method_name)
            setting.value
          elsif group = find_group(method_name)
            group
          else
            raise "unknown config setting `#{method_name}'"
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          (setter?(method_name) && find_setting(method_name[0..-2])) ||
            find_setting(method_name) ||
            find_group(method_name) ||
            super(method_name, include_private)
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
          Hash[@settings.map { |name, setting|
            [name, setting.value]
          }].merge(
            Hash[@groups.map { |name, group|
              [name, group.to_h]
            }]
          )
        end

        private

        def setter?(method_name)
          method_name[-1] == "="
        end

        def find_setting(name)
          @settings[name.to_sym]
        end

        def find_group(name)
          @groups[name.to_sym]
        end
      end
    end
  end
end
