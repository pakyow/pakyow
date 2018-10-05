# frozen_string_literal: true

require "forwardable"
require "securerandom"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/data/sources/abstract"

module Pakyow
  module Data
    module Sources
      class Ephemeral < Abstract
        class << self
          def restore(serialized)
            new(serialized[:type], **serialized[:qualifications]).set(serialized[:results])
          end
        end

        using Support::Refinements::Array::Ensurable
        attr_reader :type, :qualifications, :results

        include Enumerable

        extend Forwardable
        def_delegator :to_a, :each

        def initialize(type, **qualifications)
          @type = type
          @qualifications = { type: @type }.merge(qualifications)
          @results = []
        end

        def set(results)
          tap do
            @results = results.map { |result|
              unless result.key?(:id)
                result[:id] = SecureRandom.uuid
              end

              result
            }
          end
        end

        def serialize
          { type: @type, qualifications: @qualifications, results: @results }
        end

        def to_ary
          to_a
        end

        def to_a
          Array.ensure(@results)
        end

        COMMANDS = %i(set).freeze
        def command?(maybe_command_name)
          COMMANDS.include?(maybe_command_name)
        end

        def command(maybe_command_name)
          method(maybe_command_name)
        end

        RESULTS = %i(to_a each results).freeze
        def result?(maybe_result_name)
          RESULTS.include?(maybe_result_name)
        end

        def source_name
          @type
        end
      end
    end
  end
end
