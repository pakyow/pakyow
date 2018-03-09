# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  class UnknownValidationError < Error; end

  class InvalidData < Error
    # TODO: make this context?
    attr_reader :verifier

    def initialize(verifier = nil)
      @verifier = verifier
      super
    end
  end

  class UnknownType < Error
    def message
      known_types = @context[:types].each_with_object(String.new) { |known_type, known_types_message|
        known_types_message << "  - #{known_type.inspect}\n"
      }

      <<~MESSAGE
      Pakyow could not find a type for `#{@context[:type]}`.

      Try using one of these known types:

      #{known_types}

      MESSAGE
    end
  end
end
