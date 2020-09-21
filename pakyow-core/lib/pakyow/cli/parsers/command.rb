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
            @command.flags.each_key do |key|
              opts.on("--#{key}") do |v|
                options[key] = v
              end
            end

            @command.options.each_pair do |key, option|
              match = ["--#{key}=VAL"]
              if (short = option[:short])
                match.unshift("-#{short}VAL")
              end

              opts.on(*match) do |value|
                options[key] = value
              end
            end
          }.order!(argv) do |arg|
            unparsed << arg
          end

          argv.concat(unparsed)

          # Iterate over options again now that parsing has occurred.
          #
          @command.options.each_pair do |key, option|
            resolve_default_value!(options, option, key)

            if option[:required] && options[key].nil?
              raise CLI::InvalidInput, "`#{key}' is a required option"
            end
          end
        rescue OptionParser::InvalidOption => error
          raise CLI::InvalidInput, "`#{error.args.first}' is not a supported option"
        end

        private def parse_arguments!(argv, options)
          @command.arguments.each_pair do |key, argument|
            if argv.any?
              options[key] = argv.shift
            end

            resolve_default_value!(options, argument, key)

            if argument[:required] && options[key].nil?
              raise CLI::InvalidInput, "`#{key}' is a required argument"
            end
          end

          if argv.any?
            raise CLI::InvalidInput, "`#{argv.shift}' is not a supported argument"
          end
        end

        private def resolve_default_value!(options, option, key)
          if !options.include?(key) && option.include?(:default)
            value = option[:default]
            options[key] = case value
            when Proc
              value.call
            else
              value
            end
          end
        end
      end
    end
  end
end
