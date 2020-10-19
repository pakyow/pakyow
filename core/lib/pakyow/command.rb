# frozen_string_literal: true

require "rake"

require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"
require "pakyow/support/hookable"
require "pakyow/support/makeable"

require_relative "operation"

module Pakyow
  # Commands are callable operations that define an api through arguments, options, and flags. In
  # most cases, commands are defined through the environment and called through the command line.
  #
  # Internally, commands wrap rake to support things like dependencies.
  #
  # = Prelaunching
  #
  # Pakyow has a built-in concept called "prelaunching" that provides a way to run a sequence of
  # commands when deploying a project. Prelaunch is broken into two phases:
  #
  #   * Build: Build phase commands don't require a full boot and emit artifacts that alter the
  #     environment, such as by precompiling assets to the filesystem or uploading them to a CDN.
  #     The build phase runs when the project is being built.
  #
  #   * Release: Release phase commands require a full boot and have the ability to directly alter
  #     the environment, such as by running database migrations. The release phase runs within the
  #     deployed project just before it boots.
  #
  # Prelaunch phases are invoked through the build-in `prelaunch:build` and `prelaunch:release`
  # commands. For deployment processes that don't require separate build and release phases, all
  # prelaunch phases can be run at once through the built-in `prelaunch` command.
  #
  # Commands can hook into a prelaunch phase using the `prelaunch` hook:
  #
  #   command :some_prelaunch_command, prelaunch: :build do
  #     ...
  #   end
  #
  # Prelaunch commands that require the application context are called once for every application
  # mounted on the environment, effectively prelaunching each one:
  #
  #   command :some_prelaunch_command, prelaunch: :build do
  #     require :app
  #
  #     ...
  #   end
  #
  # Commands can hook into this behavior by passing a block to `prelaunch` that calls the command
  # with the necessary arguments for each invocation:
  #
  #   command :some_prelaunch_command do
  #     prelaunch :build do |command|
  #       command.call { ... }
  #     end
  #
  #     ...
  #   end
  #
  class Command < Operation
    include Support::Hookable
    include Support::Makeable

    extend Support::ClassState
    class_state :arguments, default: {}, inheritable: true
    class_state :options, default: {}, inheritable: true
    class_state :flags, default: {}, inheritable: true
    class_state :aliases, default: {}, inheritable: true
    class_state :__prelaunch_block, default: nil, inheritable: true

    include Support::DeepFreeze
    insulate :rake

    after "make" do
      if cli?
        verify do
          required :cli
        end
      end

      if app?
        verify do
          required :app
        end
      end

      verify do
        optional :env
        optional :debug
        optional :config
      end

      flag :debug, "Show low-level debugging information"
      option :config, "Path to the environment config file", default: Pathname.new(Pakyow.config.environment_path).relative_path_from(Pathname.new(Dir.pwd))

      rake_args = [:values]
      rake_args = if dependent
        {rake_args => dependent}
      else
        rake_args
      end

      @rake = Rake::Task.define_task(cli_name, rake_args) { |task, args|
        new(**args[:values]).perform
      }
    end

    private def deprecated_method_reference(target)
      target = if target.is_a?(Symbol) && target.to_s[-1] == "="
        target[0..-2].to_sym
      else
        target
      end

      if self.class.arguments.include?(target)
        [self, "argument `#{target}'"]
      elsif self.class.options.include?(target)
        [self, "option `#{target}'"]
      elsif self.class.flags.include?(target)
        [self, "flag `#{target}'"]
      else
        super
      end
    end

    class << self
      attr_reader :description

      # Describe what the command is and how to use it. Commands without descriptions are callable,
      # but will not appear in the list of available commands.
      #
      def describe(description)
        @description = description
      end

      # Define a named argument, with an optional description.
      #
      # Arguments are passed through the command line like this:
      #
      #   pakyow {command} {arg1} {arg2} ...
      #
      # @param required [Boolean] sets the argument as required or not
      #
      def argument(name, description = nil, required: false)
        name = name.to_sym
        @arguments[name] = {
          description: description,
          required: required
        }

        verify do
          if required
            required name
          else
            optional name
          end
        end
      end

      # Define a named option, with an optional description.
      #
      # Options are passed through the command line like this:
      #
      #   pakyow {command} --{option}={input} ...
      #
      # @param required [Boolean] sets the option as required or not
      #
      def option(name, description = nil, required: false, short: name[0], default: nil)
        name = name.to_sym
        @options[name] = {
          description: description,
          required: required
        }

        if available_short_name?(short)
          @options[name][:short] = short.to_s
        end

        unless default.nil?
          @options[name][:default] = -> {
            __verifiers[:default].default(name)
          }
        end

        verify do
          if required
            required name
          else
            optional name, default: default
          end
        end
      end

      # Define a named flag, with an optional description.
      #
      # Flags are passed through the command line like this:
      #
      #   pakyow {command} --{flag}
      #
      def flag(name, description = nil, short: name[0])
        name = name.to_sym
        @flags[name.to_sym] = {
          description: description,
          default: -> {
            __verifiers[:default].default(name)
          }
        }

        if available_short_name?(short)
          @flags[name][:short] = short.to_s
        end

        verify do
          optional name, default: false
        end
      end

      def prelaunch(phase, &block)
        @prelaunch, @__prelaunch_block = phase, block
      end

      def call(**values)
        @rake.invoke(values)
        @rake.reenable
        self
      end

      # @api private
      attr_reader :dependent

      # @api private
      def app?
        if (verifier = __verifiers[:default])
          verifier.allowable_keys.include?(:app)
        else
          false
        end
      end

      # @api private
      def cli?
        if (verifier = __verifiers[:default])
          verifier.allowable_keys.include?(:cli)
        else
          false
        end
      end

      # @api private
      def global?
        defined?(@global) && @global == true
      end

      # @api private
      def boot?
        defined?(@boot) && @boot == true
      end

      # @api private
      def prelaunch?
        defined?(@prelaunch) && !@prelaunch.nil?
      end

      # @api private
      def prelaunch_phase
        defined?(@prelaunch) && @prelaunch
      end

      # @api private
      def prelaunches(&block)
        if @__prelaunch_block
          @__prelaunch_block.call(block)
        elsif app?
          Pakyow.apps.each do |app|
            yield app: app
          end
        else
          yield
        end
      end

      # @api private
      def cli_name
        @cli_name ||= object_name.parts.join(":")
      end

      # @api private
      def flag?(key)
        @flags.include?(key.to_sym)
      end

      private def available_short_name?(name)
        # FIXME: Requiring at the top of the file causes a circular require, but `PakyowCLI` is a
        # dependency of this code. This may be a sign of a larger organizational issue.
        #
        require_relative "cli"

        name = name.to_sym

        !@options.include?(name) && !@flags.include?(name) && CLI.shortable?(name)
      end
    end
  end
end
