# frozen_string_literal: true

require "pakyow/logger/formatters/json"

module Pakyow
  class Logger
    module Formatters
      # Formats log messages as logfmt.
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

        def serialize(message)
          message.each_pair.each_with_object(String.new) { |(key, value), buffer|
            value = case value
            when Array
              value.join(",")
            else
              value.to_s
            end

            unless value =~ UNESCAPED_STRING
              value = value.dump
            end

            buffer << "#{key}=#{value} "
          }.rstrip << "\n"
        end
      end
    end
  end
end
