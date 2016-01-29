module Pakyow
  class Logger
    LEVELS = {
      :debug   => 0,
      :info    => 1,
      :warn    => 2,
      :error   => 3,
      :fatal   => 4,
      :unknown => 5,
    }

    LEVEL_COLORS = {
      :debug   => :cyan,
      :info    => :green,
      :warn    => :yellow,
      :error   => :red,
      :fatal   => :red,
      # :unknown => nil,
    }

    COLOR_TABLE = [
      :black,
      :red,
      :green,
      :yellow,
      :blue,
      :magenta,
      :cyan,
      :white,
    ]

    RESET_SEQ = "\033[0m"
    COLOR_SEQ = "\033[%dm"
    BOLD_SEQ  = "\033[1m"

    def initialize(log = $stdout, level = 0, format = false, auto_flush = false)
      level = LEVELS[level] if level.is_a?(Symbol)
      @log, @level, @format, @auto_flush = log, level, format, auto_flush
      @mutex = Mutex.new
    end

    def <<(msg = nil, severity = :unknown)
      return if @log.nil?
      (msg || "") << "\n"

      msg = format(msg, severity) if @format
      @mutex.synchronize do
        @log.write msg
        @log.flush if @auto_flush
      end
    end

    alias :write :<<

    def add(severity, msg = nil)
      severity ||= LEVELS[:unknown]
      return if severity < @level

      write(msg, severity)
    end

    alias :log :add

    def debug(msg = nil)
      add(LEVELS[:debug], msg)
    end

    def info(msg = nil)
      add(LEVELS[:info], msg)
    end

    def warn(msg = nil)
      add(LEVELS[:warn], msg)
    end

    def error(msg = nil)
      add(LEVELS[:error], msg)
    end

    def fatal(msg = nil)
      add(LEVELS[:fatal], msg)
    end

    def format(msg, level)
      return msg unless color = level_color(level)
      return COLOR_SEQ % (30 + COLOR_TABLE.index(color)) + (msg || "") + RESET_SEQ
    end

    def level_color(level)
      LEVEL_COLORS[LEVELS.key(level)]
    end

    def close
      @log.close
    end

  end
end

module Pakyow
  module Middleware
    class Logger
      # handles logging after an error occurs
      Pakyow::App.after(:error) {
        error = request.error
        Pakyow.logger.error "[500] #{error.class}: #{error}\n" + error.backtrace.join("\n") + "\n\n"
      }

      def initialize(app)
        @app = app
      end

      def call(env)
        env['rack.logger'] = Pakyow.logger

        result = nil
        difference = time { |began_at|
          Pakyow.logger << "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']} for #{env['REMOTE_ADDR']} at #{began_at}"
          result = @app.call(env)
        }

        status = result[0]
        Pakyow.logger << "#{status} (#{nice_status(status)}) in #{difference}ms\n"

        result
      end

      def time
        s = Time.now
        yield(s)
        time = ((Time.now.to_f - s.to_f) * 1000.0)
        (time * 10**2).round / (10**2).to_f
      end

      def nice_status(status)
        Pakyow::Response::STATUS_CODE_NAMES[status] || '?'
      end
    end
  end
end
