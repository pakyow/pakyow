# frozen_string_literal: true

require "pathname"
require "method_source"

require "pakyow/support/cli/style"
require "pakyow/support/inflector"

module Pakyow
  # Base error object.
  #
  class Error < StandardError
    class << self
      # Wraps an error in a pakyow error instance, with additional context.
      #
      def build(original_error, context: nil)
        if original_error.is_a?(self)
          original_error
        else
          # TODO: consider not including the original error class, since it's included elsewhere in the trace
          #
          new("#{original_error.class}: #{original_error.message}").tap do |error|
            error.wrapped_exception = original_error
            error.set_backtrace(original_error.backtrace)
            error.context = context
          end
        end
      end
    end

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
      if project? && location = project_backtrace_locations[0]
        <<~MESSAGE
          `#{(cause || self).class}` occurred on line `#{location.lineno}` of `#{path}`:

          #{indent_as_source(MethodSource.source_helper([path, location.lineno], location.label), location.lineno)}
        MESSAGE
      elsif location = (cause || self).backtrace_locations.to_a[0]
        library_name = gem_name(location.absolute_path)
        occurred_in = if library_name.start_with?("pakyow-")
          "`#{library_name.split("-", 2)[1]}` framework"
        else
          "`#{library_name}` gem"
        end

        <<~MESSAGE
          `#{(cause || self).class}` occurred outside of your project, within the #{occurred_in}.
        MESSAGE
      else
        <<~MESSAGE
          `#{(cause || self).class}` occurred at an unknown location.
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
          File.expand_path(project_backtrace_locations[0].absolute_path)
        ).relative_path_from(
          Pathname.new(Pakyow.config.root)
        ).to_s
      else
        File.expand_path(project_backtrace_locations[0].absolute_path)
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
          gem_name(line).to_s.gsub(/^pakyow-/, "")
        }.max_by(&:length).length + 3

        backtrace.map { |line|
          modified_line = strip_path_prefix(line)
          if line.start_with?(Pakyow.config.root)
            "› ".rjust(padded_length) + modified_line
          else
            "#{gem_name(line).to_s.gsub(/^pakyow-/, "")} | ".rjust(padded_length) + modified_line.split("/", 2)[1]
          end
        }
      end
    end

    private

    def project_backtrace_locations
      (cause || self).backtrace_locations.to_a.select { |line|
        File.expand_path(line.absolute_path).start_with?(Pakyow.config.root)
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
          start << "›"
        else
          start << " "
        end
        "#{start} #{line}"
      }.join("\n")
    end

    LOCAL_FRAMEWORK_PATH = File.expand_path("../../../../", __FILE__)

    def strip_path_prefix(line)
      if line.start_with?(Pakyow.config.root)
        line.gsub(/^#{Pakyow.config.root}\//, "")
      elsif line.start_with?(Gem.default_dir)
        line.gsub(/^#{Gem.default_dir}\/gems\//, "")
      elsif line.start_with?(LOCAL_FRAMEWORK_PATH)
        line.gsub(/^#{LOCAL_FRAMEWORK_PATH}\//, "")
      else
        line
      end
    end

    def gem_name(line)
      if line.start_with?(Gem.default_dir)
        strip_path_prefix(line).split("/")[0].split("-")[0..-2].join("-")
      elsif line.start_with?(LOCAL_FRAMEWORK_PATH)
        strip_path_prefix(line).split("/")[0]
      else
        nil
      end
    end

    # @api private
    class CLIFormatter
      def initialize(error)
        @error = error
      end

      def to_s
        <<~MESSAGE
        #{Support::CLI.style.white.on_red.bold(header)}

        #{indent(@error.message)}

        #{Support::CLI.style.black.on_white.bold(" DETAILS                                                                        ")}

        #{indent(@error.details)}

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

      private

      def indent(message)
        message.split("\n").map { |line|
          "  #{line}"
        }.join("\n")
      end

      def backtrace
        @error.condensed_backtrace.map(&:to_s).join("\n")
      end
    end
  end
end
