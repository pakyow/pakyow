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

    def initialize(log = $stdout, level = 0, format = false)
      @log, @level, @format = log, level, format
      @mutex = Mutex.new
    end

    def <<(msg = nil, severity = @level)
      msg << "\n"

      msg = format(msg, severity) if @format
      @mutex.synchronize do
        @log.write msg
        @log.flush
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
      return COLOR_SEQ % (30 + COLOR_TABLE.index(color)) + msg + RESET_SEQ
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
        Pakyow.logger.error "[500] #{error}\n" + error.backtrace.join("\n") + "\n\n"
      }

      def initialize(app)
        Pakyow.configure_logger

        @app = app
      end

      def call(env)
        env['rack.logger'] = Pakyow.logger

        result = nil
        difference = time { |began_at|
          Pakyow.logger.info "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']} for #{env['REMOTE_ADDR']} at #{began_at}"
          result = @app.call(env)
        }

        status = result[0]
        Pakyow.logger.info "#{status} (#{nice_status(status)}) in #{difference}ms\n"

        result
      end

      def time
        s = Time.now
        yield(s)
        time = ((Time.now.to_f - s.to_f) * 1000.0)
        (time * 10**2).round / (10**2).to_f
      end

      def nice_status(status)
        {
          100 => 'Continue',
          101 => 'Switching Protocols',

          200 => 'OK',
          201 => 'Created',
          202 => 'Accepted',
          203 => 'Non-Authoritative Information',
          204 => 'No Content',
          205 => 'Reset Content',
          206 => 'Partial Content',

          300 => 'Multiple Choices',
          301 => 'Moved Permanently',
          302 => 'Found',
          303 => 'See Other',
          304 => 'Not Modified',
          305 => 'Use Proxy',
          306 => 'Switch Proxy',
          307 => 'Temporary Redirect',

          400 => 'Bad Request',
          401 => 'Unauthorized',
          402 => 'Payment Required',
          403 => 'Forbidden',
          404 => 'Not Found',
          405 => 'Method Not Allowed',
          406 => 'Not Acceptable',
          407 => 'Proxy Authentication Required',
          408 => 'Request Timeout',
          409 => 'Conflict',
          410 => 'Gone',
          411 => 'Length Required',
          412 => 'Precondition Failed',
          413 => 'Request Entity Too Large',
          414 => 'Request-URI Too Long',
          415 => 'Unsupported Media Type',
          416 => 'Requested Range Not Satisfiable',
          417 => 'Expectation Failed',
          418 => 'I\'m a teapot',

          500 => 'Internal Server Error',
          501 => 'Not Implemented',
          502 => 'Bad Gateway',
          503 => 'Service Unavailable',
          504 => 'Gateway Timeout',
          505 => 'HTTP Version Not Supported',
          506 => 'Variant Also Negotiates',
          507 => 'Insufficient Storage',
          508 => 'Loop Detected',
          509 => 'Bandwidth Limit Exceeded',
          510 => 'Not Extended',
          511 => 'Network Authentication Required'
        }[status] || '?'
      end
    end
  end
end
