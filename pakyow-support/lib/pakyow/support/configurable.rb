module Pakyow
  module Support
    module Configurable
      class Config
        def initialize
          @groups = {}
        end

        def add_group(name, options, parent, &block)
          settings = ConfigGroup.new(name, options, parent, &block)
          @groups[name.to_sym] = settings
        end

        def method_missing(name)
          @groups[name]
        end

        def freeze
          super

          # TODO: freeze all the other things
        end
      end

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

      # TODO: rename to ConfigOption
      class ConfigOption
        attr_reader :name
        attr_writer :value

        def initialize(name, default)
          @name = name
          @default = default
        end

        # TODO: would this work if `parent` was part of initialization or would that not be thread-safe?
        def value(parent)
          @value || default(parent)
        end

        def default(parent)
          if @default.is_a?(Proc)
            parent.instance_eval(&@default)
          else
            @default
          end
        end
      end

      def self.included(base)
        base.extend ClassAPI
      end

      def use_config(env)
        @config = self.class.config.dup
        [:__global, env.to_sym].each do |config_env|
          next unless config_block = self.class.config_envs[config_env]
          instance_eval(&config_block)
        end

        config.freeze
        self.class.config.freeze
      end

      def config
        @config
      end

      module ClassAPI
        def config
          @config ||= Config.new
        end

        def settings_for(group, **options, &block)
          raise ArgumentError, "Expected group name" unless group
          raise ArgumentError, "Expected block" unless block_given?
          config.add_group(group, options, self, &block)
        end

        def configure(env = :__global, &block)
          config_envs[env] = block
        end

        def use_config(env)
          [:__global, env.to_sym].each do |config_env|
            next unless config_block = config_envs[config_env]
            instance_eval(&config_block)
          end

          config.freeze
        end

        def config_envs
          @config_envs ||= {}
        end
      end
    end
  end
end
