# frozen_string_literal: true

require "json"

require "pakyow/error"

module Pakyow
  class InvalidData < Error
    # Failed verifier instance.
    #
    def verifier
      @context[:verifier]
    end

    def object
      @context[:object]
    end

    def message
      <<~MESSAGE
      Verification failed for the following data:

      #{indent_as_code(JSON.pretty_generate(object))}

      Here are the failures:

      #{indent_as_code(JSON.pretty_generate(verifier.messages))}
      MESSAGE
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

  class UnknownValidationError < Error
  end
end
