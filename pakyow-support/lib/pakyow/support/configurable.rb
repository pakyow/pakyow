# frozen_string_literal: true

require "pakyow/support/configurable/config"
require "pakyow/support/configurable/config_group"
require "pakyow/support/configurable/config_option"

require "pakyow/support/class_state"

module Pakyow
  module Support
    module Configurable
      def self.included(base)
        base.extend ClassAPI
        base.extend ClassState
        base.class_state :config, default: Config.new, inheritable: true
        base.class_state :config_envs, default: {}, inheritable: true
      end

      attr_reader :config

      def use_config(env)
        @config = self.class.config.dup

        @config.load_defaults(env)
        [:__global, env.to_sym].each do |config_env|
          next unless config_block = self.class.config_envs[config_env]
          instance_eval(&config_block)
        end

        @config.freeze
      end

      module ClassAPI
        def inherited(subclass)
          super

          subclass.config.groups.values.each do |group|
            group.instance_variable_set(:@__parent, subclass)
          end
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
          config.load_defaults(env)
          [:__global, env.to_sym].each do |config_env|
            next unless config_block = config_envs[config_env]
            instance_eval(&config_block)
          end

          config.freeze
        end
      end
    end
  end
end
