require "pakyow/support/configurable/config_option"

module Pakyow
  module Support
    module Configurable
      class ConfigGroup
        attr_reader :name, :options, :parent, :settings, :defaults

        def initialize(name, options, parent, &block)
          @name = name
          @options = options
          @parent = parent
          @settings = {}
          @defaults = {}

          instance_eval(&block)
        end

        def setting(name, default = nil, &block)
          name = name.to_sym
          @settings[name] = ConfigOption.new(name, default.nil? ? block : default)
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
          if value && name[-1] == "="
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
      end
    end
  end
end
