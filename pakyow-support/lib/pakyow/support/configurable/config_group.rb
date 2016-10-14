require "pakyow/support/configurable/config_option"

module Pakyow
  module Support
    module Configurable
      class ConfigGroup
        def initialize(name, options, parent, &block)
          @name = name
          @options = options
          @parent = parent
          @settings = {}
          @defaults = {}

          instance_eval(&block)
        end

        def setting(name, default = nil, &block)
          @settings[name.to_sym] = ConfigOption.new(name, default || block)
        end

        def defaults(env, &block)
          # TODO: do something with these (creating another SettingsGroup)
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
