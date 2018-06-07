# frozen_string_literal: true

require "pathname"

require "pastel"
require "method_source"

module Pakyow
  # Base Pakyow error object.
  #
  class Error < StandardError
    attr_accessor :wrapped_exception, :context

    def initialize(*)
      @context = nil

      super
    end

    # @api private
    def cause
      wrapped_exception || super
    end

    def backtrace_locations
      if wrapped_exception
        wrapped_exception.backtrace_locations
      else
        super
      end
    end

    def url
      "https://pakyow.com/docs"
    end

    def name
      Support.inflector.humanize(
        Support.inflector.underscore(
          Support.inflector.demodulize(self.class.name)
        )
      )
    end

    def details
      if framework_error?
        <<~MESSAGE
        `#{self.class}` was raised from within the framework.
        MESSAGE
      else
        line = root_backtrace_locations[0]

        <<~MESSAGE
        `#{self.class}` occurred on line `#{line.lineno}` of `#{path}`:

        #{indent_as_source(MethodSource.source_helper([path, line.lineno], line.label), line.lineno)}
        MESSAGE
      end
    end

    ROOT_PATH = File.expand_path(".")

    def path
      @path ||= if framework_error?
        ""
      else
        Pathname.new(
          File.expand_path(root_backtrace_locations[0].absolute_path)
        ).relative_path_from(
          Pathname.new(ROOT_PATH)
        ).to_s
      end
    end

    def framework_error?
      root_backtrace_locations.empty?
    end

    def set_backtrace(backtrace)
      if framework_error?
        # Error didn't originate from the app, so display the full backtrace.
        #
        super
      else
        super(root_backtrace_locations.map { |line|
          "#{Pathname.new(File.expand_path(line.absolute_path)).relative_path_from(Pathname.new(ROOT_PATH)).to_s}:#{line.lineno}:#{line.label}"
        })
      end
    end

    private

    def root_backtrace_locations
      backtrace_locations.to_a.select { |line|
        File.expand_path(line.absolute_path).include?(ROOT_PATH)
      }
    end

    def indent_as_code(message)
      message.split("\n").map { |line|
        "    #{line}"
      }.join("\n")
    end

    def indent_as_source(message, lineno)
      message.split("\n").each_with_index.map { |line, i|
        start = String.new("    #{lineno + i}|")
        if i == 0
          start << ">"
        else
          start << " "
        end
        "#{start} #{line}"
      }.join("\n")
    end

    # @api private
    class CLIFormatter
      def initialize(error)
        @error = error
        @pastel = Pastel.new
      end

      def to_s
        <<~MESSAGE
        #{@pastel.black.on_red.bold(header)}

        #{indent(@error.message)}

        #{@pastel.blue(indent("<#{@error.url}>"))}

        #{@pastel.black.on_white.bold(" DETAILS                                                                        ")}

        #{indent(@error.details)}

        #{@pastel.black.on_white.bold(" BACKTRACE                                                                      ")}

        #{@error.backtrace.map { |line| indent(line) }.join("\n")}
        MESSAGE
      end

      def header
        start = " #{@error.name.upcase} "

        finish = if @error.framework_error?
          ""
        else
          File.basename(@error.path)
        end

        "#{start}#{" " * (80 - (start.length + finish.length + 2))} #{finish} "
      end

      private

      def indent(message)
        message.split("\n").map { |line|
          " #{line}"
        }.join("\n")
      end
    end
  end

  # @api private
  def self.build_error(original_error, error_class, context: nil)
    if original_error.is_a?(error_class)
      original_error
    else
      error_class.new("#{original_error.class}: #{original_error.message}").tap do |error|
        error.wrapped_exception = original_error
        error.set_backtrace(original_error.backtrace)
        error.context = context
      end
    end
  end
end
