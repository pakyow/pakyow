# frozen_string_literal: true

require "pakyow/logger/formatters/json"

module Pakyow
  class Logger
    module Formatters
      # Used by {Pakyow::RequestLogger} to format request / response lifecycle messages in logfmt.
      #
      # @example
      #   severity=INFO timestamp="2016-06-20 10:08:29 -0500" id=678cf582 type=http elapsed=0.01ms method=GET uri=/ ip=127.0.0.1
      #   severity=INFO timestamp="2016-06-20 10:08:29 -0500" id=678cf582 type=http elapsed=1.56ms message="hello 2016-06-20 10:08:29 -0500"
      #   severity=INFO timestamp="2016-06-20 10:08:29 -0500" id=678cf582 type=http elapsed=3.37ms status=200
      #
      # @api private
      class Logfmt < Pakyow::Logger::Formatters::JSON
        private

        UNESCAPED_STRING = /\A[\w\.\-\+\%\,\:\;\/]*\z/i

        def format(message)
          message.delete(:time)
          escape(message).map { |key, value|
            "#{key}=#{value}"
          }.join(" ") + "\n"
        end

        # From polyfox/moon-logfmt.
        #
        def escape(message)
          return to_enum :escape, message unless block_given?

          message.each_pair do |key, value|
            value = case value
            when Array
              value.join(",")
            else
              value.to_s
            end

            value = value.dump unless value =~ UNESCAPED_STRING
            yield key.to_s, value
          end
        end
      end
    end
  end
end
