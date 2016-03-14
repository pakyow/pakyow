require_relative 'errors'

module Pakyow
  class Config
    class << self
      attr_accessor :env
    end

    def self.register(name)
      config = Pakyow::Config.new(name)
      yield(config.defaults)

      @config ||= {}
      @config[name] = config

      self.class.instance_eval do
        define_method(name) { @config[name] }
      end

      config
    end

    def self.deregister(name)
      @config.delete(name)
    end

    def self.reset
      @config.values.each(&:reset)
    end

    def self.app_config(&block)
      instance_eval(&block)
    end

    attr_reader :config_name

    def initialize(name, default_config: false)
      @config_name = name
      @opts = {}
      @envs = {}
      @default_config = default_config
    end

    def defaults
      return if @default_config # don't define defaults for defaults
      @defaults ||= Pakyow::Config.new("#{@config_name}.defaults", default_config: true)
    end

    def env(name)
      config = Pakyow::Config.new("#{@config_name}.#{name}")
      yield(config)

      @envs[name] = config
      self
    end

    def clear_env(name)
      @envs.delete(name)
    end

    def value(name, *args)
      value = @opts.fetch(name) { raise(ConfigError.new("No config value available for `#{@config_name}.#{name}`")) }
      value = instance_exec(*args, &value) if value.is_a?(Proc)
      value
    end

    def opt(name, default = nil)
      context = defaults ? defaults : self
      context.instance_variable_get(:@opts)[name] = default
    end

    def reset
      @opts = {}
    end

    def method_missing(method, *args)
      if /^(\w+)=$/ =~ method
        @opts[$1.to_sym] = args[0]
      else
        configs = [self]
        configs << @envs[Config.env] if @envs.key?(Config.env)
        configs << @defaults unless @defaults.nil?

        configs.each do |config|
          begin
            return config.value(method, *args)
          rescue ConfigError
          end
        end

        raise(ConfigError.new("No config value available for `#{@config_name}.#{method}`"))
      end
    end
  end
end
