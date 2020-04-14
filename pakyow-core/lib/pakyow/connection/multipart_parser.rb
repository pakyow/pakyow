# frozen_string_literal: true

require "multipart_parser/reader"
require "protocol/http/headers"

require_relative "../error"

require_relative "multipart_input"

module Pakyow
  class Connection
    class MultipartParser
      class LimitExceeded < Error; end
      class ParseError < Error; end

      DEFAULT_MULTIPART_LIMIT = 100

      attr_reader :values

      def initialize(params, boundary:)
        @params, @boundary = params, boundary.to_s.gsub(/[\"\']/, "")
        @reader = ::MultipartParser::Reader.new(@boundary)
        @reader.on_part(&method(:on_part))
        @reader.on_error(&method(:on_error))
        @values = []
        @size = 0
      end

      def parse(input)
        while data = input.read
          @reader.write(data)
        end

        finalize
        @params
      rescue StandardError => error
        ensure_closed
        if error.is_a?(LimitExceeded)
          raise error
        else
          raise ParseError.build(error)
        end
      end

      private

      def finalize
        @values.select { |value|
          value.is_a?(MultipartInput)
        }.each(&:rewind)
      end

      def add(value)
        @values << value

        if value.is_a?(MultipartInput)
          @size += 1
        end

        if @size > DEFAULT_MULTIPART_LIMIT
          raise LimitExceeded, "multipart limit (#{DEFAULT_MULTIPART_LIMIT}) exceeded"
        end

        value
      end

      def on_part(part)
        headers = Protocol::HTTP::Headers.new(part.headers).to_h
        disposition = QueryParser.new.tap { |parser|
          parser.parse(headers["content-disposition"].to_s)
        }.params
        content_type = QueryParser.new.tap { |parser|
          parser.parse(headers["content-type"].to_s)
        }.params

        if filename = disposition["filename"]
          value = add(MultipartInput.new(filename: filename, headers: headers, type: part.mime))

          part.on_data do |data|
            value << data
          end
        else
          value = add(String.new)
          encoding = if charset = content_type["charset"]
            Encoding.find(charset.gsub(/[^a-zA-Z0-9\-_]/, ""))
          else
            Encoding::UTF_8
          end

          value.force_encoding(encoding)

          part.on_data do |data|
            value << data
          end
        end

        @params.add_value_for_key(value, part.name || disposition["filename"])
      end

      def on_error(error)
        ensure_closed
        raise ParseError, error
      end

      def ensure_closed
        @values.each do |value|
          value.close if value.is_a?(MultipartInput)
        end
      end
    end
  end
end
