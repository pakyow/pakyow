# frozen_string_literal: true

require "optparse"

module Pakyow
  class CLI
    module Parsers
      # Parses command line arguments for a specific command.
      #
      # @api private
      class Command
        def initialize(command, argv)
          @command, @argv = command, argv
        end

        def options
          unless defined?(@options)
            options = {}
            parse_options!(@argv, options)
            parse_arguments!(@argv, options)
            @options = options
          end

          @options
        end

        private def parse_options!(argv, options)
          unparsed = []

          OptionParser.new { |opts|
            @command.flags.keys.each do |flag|
              opts.on("--#{flag}") do |v|
                options[flag] = v
              end
            end

            @command.options.keys.each do |option|
              match = ["--#{option}=VAL"]
              if @command.short_names.key?(option)
                match.unshift("-#{@command.short_names[option]}VAL")
              end

              opts.on(*match) do |v|
                options[option] = v
              end
            end
          }.order!(argv) do |arg|
            unparsed << arg
          end

          argv.concat(unparsed)
        rescue OptionParser::InvalidOption => error
          raise CLI::InvalidInput, "`#{error.args.first}' is not a supported option"
        end

        def parse_arguments!(argv, options)
          @command.arguments.each do |key, argument|
            if argv.any?
              options[key] = argv.shift
            elsif argument[:required]
              raise CLI::InvalidInput, "`#{key}' is a required argument"
            end
          end

          if argv.any?
            raise CLI::InvalidInput, "`#{argv.shift}' is not a supported argument"
          end
        end
      end
    end
  end
end
