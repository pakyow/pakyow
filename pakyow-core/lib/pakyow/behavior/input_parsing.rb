# frozen_string_literal: true

require "json"

require "pakyow/support/extension"
require "pakyow/support/indifferentize"

require_relative "../connection/query_parser"
require_relative "../connection/multipart_parser"

module Pakyow
  module Behavior
    module InputParsing
      extend Support::Extension
      using Support::Indifferentize

      apply_extension do
        class_state :input_parsers, default: {}

        on "configure" do
          Pakyow.parse_input "application/x-www-form-urlencoded" do |input, connection|
            connection.params.parse(input.read)
          end

          Pakyow.parse_input "multipart/form-data" do |input, connection|
            Connection::MultipartParser.new(
              connection.params, boundary: connection.type_params[:boundary]
            ).parse(input)
          end

          Pakyow.parse_input "application/json", rewindable: true do |input, connection|
            values = JSON.parse(input.read)

            if values.is_a?(Hash)
              values.deep_indifferentize.each do |key, value|
                connection.params.add(key, value)
              end
            end

            values
          end
        end
      end

      class_methods do
        def parse_input(type, rewindable: true, &block)
          @input_parsers[type] = {
            block: block,
            rewindable: rewindable
          }
        end
      end
    end
  end
end
