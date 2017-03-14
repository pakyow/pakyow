require "pakyow/support/configurable/config_option"
require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      class ConfigGroup
        using DeepDup
        attr_reader :_name, :_options, :_parent, :_settings

        def initialize(name, options, parent, &block)
          @_name = name
          @_options = options
          @_parent = parent
          @_settings = {}
          @_initial_settings = {}
          @_defaults = {}

          instance_eval(&block)
          @initialized = true
        end

        def setting(name, default = nil, &block)
          name = name.to_sym
          option = ConfigOption.new(name, default.nil? ? block : default)

          unless instance_variable_defined?(:@initialized)
            # keep up with the initial values so we can reset
            @_initial_settings[name] = option
          end

          @_settings[name] = option
        end

        def defaults(env, &block)
          env = env.to_sym
          if block_given?
            @_defaults[env] = block
          else
            @_defaults[env]
          end
        end

        def method_missing(name, value = nil)
          if name[-1] == "="
            name = name[0..-2].to_sym
            @_settings.fetch(name) {
              if extendable?
                setting(name)
              else
                raise NameError, "No config setting named #{name}"
              end
            }.value = value
          else
            @_settings.fetch(name) {
              return nil
            }.value(@_parent)
          end
        end

        def extendable?
          @_options[:extendable] == true
        end

        def reset
          @_settings = @_initial_settings.deep_dup

          @_settings.each do |_, settings|
            settings.reset
          end
        end
      end
    end
  end
end
