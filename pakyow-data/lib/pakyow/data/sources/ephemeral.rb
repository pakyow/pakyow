# frozen_string_literal: true

require "securerandom"

require "pakyow/data/sources/abstract"

module Pakyow
  module Data
    module Sources
      class Ephemeral < Abstract
        attr_reader :type, :id, :value

        def initialize(type, id: nil)
          @type, @id = type, (id || SecureRandom.uuid)
          @value = nil
        end

        def set(value)
          tap do
            @value = value
          end
        end

        def to_h
          {
            id: @id,
            type: @type,
            value: @value
          }
        end

        def to_a
          [to_h]
        end

        def map(&block)
          to_a.map(&block)
        end

        def qualifications
          { type: @type, id: @id }
        end

        COMMANDS = %i(set).freeze
        def command?(maybe_command_name)
          COMMANDS.include?(maybe_command_name)
        end

        def command(maybe_command_name)
          method(maybe_command_name)
        end

        RESULTS = %i(value).freeze
        def result?(maybe_result_name)
          RESULTS.include?(maybe_result_name)
        end

        def command(maybe_command_name)
          method(maybe_command_name)
        end

        def source_name
          @type
        end
      end
    end
  end
end
