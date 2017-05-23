require "pakyow/support/configurable/config_option"
require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      class ConfigGroup
        using DeepDup
        attr_reader :__name, :__options, :__parent, :__settings

        def initialize(name, options, parent, &block)
          @__name = name
          @__options = options
          @__parent = parent
          @__settings = {}
          @__initial_settings = {}
          @__defaults = {}

          instance_eval(&block)
          @initialized = true
        end
        
        def initialize_copy(original)
          @__settings = original.__settings.deep_dup
        end

        def setting(name, default = nil, &block)
          name = name.to_sym
          option = ConfigOption.new(name, default.nil? ? block : default)

          unless instance_variable_defined?(:@initialized)
            # keep up with the initial values so we can reset
            @__initial_settings[name] = option
          end

          @__settings[name] = option
        end

        def defaults(env, &block)
          env = env.to_sym
          if block_given?
            @__defaults[env] = block
          else
            @__defaults[env]
          end
        end

        def method_missing(name, value = nil)
          if name[-1] == "="
            name = name[0..-2].to_sym
            @__settings.fetch(name) {
              if extendable?
                setting(name)
              else
                raise NameError, "No config setting named #{name}"
              end
            }.value = value
          else
            @__settings.fetch(name) {
              return nil
            }.value(@__parent)
          end
        end

        def extendable?
          @__options[:extendable] == true
        end

        def reset
          @__settings = @__initial_settings.deep_dup

          @__settings.each do |_, settings|
            settings.reset
          end
        end
      end
    end
  end
end
