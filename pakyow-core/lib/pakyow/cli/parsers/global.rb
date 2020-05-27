# frozen_string_literal: true

require "optparse"

module Pakyow
  class CLI
    module Parsers
      # Parses command line arguments into a command + options.
      #
      # @api private
      class Global
        def initialize(argv)
          @argv = argv
        end

        def command
          @command ||= parse_command!(@argv)
        end

        def options
          @options ||= parse_options!(@argv)
        end

        private def parse_command!(argv)
          if argv.any? && !argv[0].start_with?("-")
            argv.shift
          else
            nil
          end
        end

        private def parse_options!(argv)
          options = {}

          parse_with_unknown_args!(argv) do
            OptionParser.new do |opts|
              opts.on("-eENV", "--env=ENV") do |e|
                options[:env] = e
              end

              opts.on("-aAPP", "--app=APP") do |a|
                options[:app] = a
              end

              opts.on("-h", "--help") do
                options[:help] = true
              end

              opts.on("--debug") do
                options[:debug] = true
              end
            end
          end

          options[:env] ||= ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
          ENV["APP_ENV"] = ENV["RACK_ENV"] = options[:env]
          options
        end

        private def parse_with_unknown_args!(argv)
          parser, original, unparsed = yield, argv.dup, Array.new

          begin
            parser.order!(argv) do |arg|
              unparsed << arg
            end
          rescue OptionParser::InvalidOption => error
            unparsed.concat(error.args); retry
          end

          argv.replace((original & argv) + unparsed)
        end
      end
    end
  end
end
