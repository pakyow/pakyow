# frozen_string_literal: true

require "pathname"
require "method_source"

require "pakyow/support/class_state"
require "pakyow/support/cli/style"
require "pakyow/support/dependencies"
require "pakyow/support/inflector"
require "pakyow/support/string_builder"

module Pakyow
  # Base error object.
  #
  class Error < StandardError
    class << self
      # Wraps an error in a pakyow error instance, with additional context.
      #
      def build(original_error, message_type = :default, context: nil, **message_values)
        if original_error.is_a?(self)
          original_error
        else
          message = message(message_type, **message_values)
          message = original_error.message if message.empty?

          error = new(message)
          error.wrapped_exception = original_error
          error.set_backtrace(original_error.backtrace)
          error.context = context
          error
        end
      end

      # Initialize an error with a particular message.
      #
      def new_with_message(type = :default, **values)
        new(message(type, **values))
      end

      private

      def message(type = :default, **values)
        if @messages.include?(type)
          Support::StringBuilder.new(
            @messages[type]
          ).build(**values)
        else
          ""
        end
      end
    end

    extend Support::ClassState
    class_state :messages, default: {}, inheritable: true

    attr_accessor :wrapped_exception, :context

    def initialize(*)
      @context = nil

      super
    end

    def cause
      wrapped_exception || super
    end

    def name
      Support.inflector.humanize(
        Support.inflector.underscore(
          Support.inflector.demodulize(self.class.name)
        )
      )
    end

    def details
      if project? && (location = project_backtrace_locations[0])
        message = "`#{(cause || self).class}' occurred on line `#{location.lineno}' of `#{path}':"

        begin
          <<~MESSAGE
            #{message}

            #{indent_as_source(MethodSource.source_helper([path, location.lineno], location.label), location.lineno)}
          MESSAGE
        rescue
          <<~MESSAGE
            #{message}

                Error parsing source.
          MESSAGE
        end
      elsif (location = (cause || self).backtrace_locations.to_a[0])
        library_name = Support::Dependencies.library_name(location.absolute_path)
        library_type = Support::Dependencies.library_type(location.absolute_path)

        occurred_in = if library_type == :pakyow || library_name.start_with?("pakyow-")
          "within the `#{library_name.split("-", 2)[1]}' framework"
        elsif library_type == :gem || library_type == :bundler
          "within the `#{library_name}' gem"
        else
          "somewhere within ruby itself"
        end

        <<~MESSAGE
          `#{(cause || self).class}' occurred outside of your project, #{occurred_in}.
        MESSAGE
      else
        <<~MESSAGE
          `#{(cause || self).class}' occurred at an unknown location.
        MESSAGE
      end
    end

    # If the error occurred in the project, returns the relative path to where
    # the error occurred. Otherwise returns the absolute path to where the
    # error occurred.
    #
    def path
      @path ||= if project?
        Pathname.new(
          File.expand_path(project_backtrace_locations[0].absolute_path.to_s)
        ).relative_path_from(
          Pathname.new(Pakyow.config.root)
        ).to_s
      else
        File.expand_path(project_backtrace_locations[0].absolute_path.to_s)
      end
    end

    # Returns true if the error occurred in the project.
    #
    def project?
      File.expand_path(backtrace[0].to_s).start_with?(Pakyow.config.root)
    end

    # Returns the backtrace without any of the framework locations, unless the
    # error originated from the framework. Return value is as an array of
    # strings rather than backtrace location objects.
    #
    def condensed_backtrace
      if project?
        project_backtrace_locations.map { |line|
          line.to_s.gsub(/^#{Pakyow.config.root}\//, "")
        }
      else
        padded_length = backtrace.map { |line|
          Support::Dependencies.library_name(line).to_s.gsub(/^pakyow-/, "")
        }.max_by(&:length).length + 3

        backtrace.map { |line|
          modified_line = Support::Dependencies.strip_path_prefix(line)
          if line.start_with?(Pakyow.config.root)
            "› ".rjust(padded_length) + modified_line
          elsif modified_line.start_with?("ruby")
            "ruby | ".rjust(padded_length) + modified_line.split("/", 3)[2].to_s
          else
            "#{Support::Dependencies.library_name(line).to_s.gsub(/^pakyow-/, "")} | ".rjust(padded_length) + modified_line.split("/", 2)[1].to_s
          end
        }
      end
    end

    private

    def project_backtrace_locations
      (cause || self).backtrace_locations.to_a.select { |line|
        File.expand_path(line.absolute_path.to_s).start_with?(Pakyow.config.root)
      }
    end

    def indent_as_code(message)
      message.split("\n").map { |line|
        "    #{line}"
      }.join("\n")
    end

    def indent_as_source(message, lineno)
      message.split("\n").each_with_index.map { |line, i|
        start = +"    #{lineno + i}|"
        start << if i == 0
          "›"
        else
          " "
        end
        "#{start} #{line}"
      }.join("\n")
    end

    # @api private
    class CLIFormatter
      def initialize(error)
        @error = error
      end

      def to_s
        <<~MESSAGE
          #{message}

          #{Support::CLI.style.black.on_white.bold(" DETAILS                                                                        ")}

          #{details}

          #{Support::CLI.style.black.on_white.bold(" BACKTRACE                                                                      ")}

          #{backtrace}
        MESSAGE
      end

      def header
        start = " #{@error.name.upcase} "

        finish = if @error.project?
          File.basename(@error.path)
        else
          ""
        end

        "#{start}#{" " * (80 - (start.length + finish.length + 2))} #{finish} "
      end

      def message
        message = Support::CLI.style.white.on_red.bold(header).dup
        message_lines = @error.message.split("\n")
        if message_lines.any?
          message << "\n\n#{self.class.indent(Support::CLI.style.red("›") + Support::CLI.style.bright_black(" #{self.class.format(message_lines.shift)}"))}\n"
          message_lines.each do |line|
            message << Support::CLI.style.bright_black("\n#{line}")
          end
        end

        if @error.respond_to?(:contextual_message)
          message = <<~MESSAGE
            #{message}
            #{Support::CLI.style.bright_black(self.class.indent(self.class.format(@error.contextual_message)))}
          MESSAGE
        end

        message.rstrip
      end

      def details
        Support::CLI.style.bright_black(self.class.indent(self.class.format(@error.details)))
      end

      def backtrace
        @error.condensed_backtrace.map(&:to_s).join("\n")
      end

      private

      class << self
        # @api private
        def indent(message)
          message.split("\n").map { |line|
            "  #{line}"
          }.join("\n")
        end

        # @api private
        HIGHLIGHT_REGEX = /`([^']*)'/

        # @api private
        def format(message)
          message_to_format = message.dup

          message.scan(HIGHLIGHT_REGEX).each do |match|
            message_to_format.gsub!("`#{match[0]}'", Support::CLI.style.italic.blue(match[0]))
          end

          message_to_format
        end
      end
    end
  end
end
