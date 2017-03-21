require "pakyow/support/configurable/config_option"
require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      class ConfigGroup
        using DeepDup
        attr_reader :name, :options, :parent, :settings

        def initialize(name, options, parent, &block)
          @name = name
          @options = options
          @parent = parent
          @settings = {}
          @initial_settings = {}
          @defaults = {}

          instance_eval(&block)
          @initialized = true
        end

        def setting(name, default = nil, &block)
          name = name.to_sym
          option = ConfigOption.new(name, default.nil? ? block : default)

          unless instance_variable_defined?(:@initialized)
            # keep up with the initial values so we can reset
            @initial_settings[name] = option
          end

          @settings[name] = option
        end

        def defaults(env, &block)
          env = env.to_sym
          if block_given?
            @defaults[env] = block
          else
            @defaults[env]
          end
        end

        def method_missing(name, value = nil)
          if name[-1] == "="
            name = name[0..-2].to_sym
            @settings.fetch(name) {
              if extendable?
                setting(name)
              else
                raise NameError, "No config setting named #{name}"
              end
            }.value = value
          else
            @settings.fetch(name) {
              return nil
            }.value(@parent)
          end
        end

        def extendable?
          @options[:extendable] == true
        end

        def reset
          @settings = @initial_settings.deep_dup

          @settings.each do |_, settings|
            settings.reset
          end
        end
      end
    end
  end
end
