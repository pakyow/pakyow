module Pakyow
  module Config
    class Logger
      Config::Base.register_config(:logger, self)

      class << self
        attr_accessor :path, :name, :sync, :colorize, :auto_flush, :level

        # Path to logs
        def path
          @path || "#{Config::Base.app.root}/logs"
        end

        def name
          @name || "requests.log"
        end

        def sync
          instance_variable_defined?(:@sync) ? @sync : true
        end

        def auto_flush
          instance_variable_defined?(:@auto_flush) ? @auto_flush : true
        end

        def colorize
          instance_variable_defined?(:@colorize) ? @colorize : true
        end

        def level
          @level || Pakyow::Logger::LEVELS[:debug]
        end

      end
    end
  end
end
