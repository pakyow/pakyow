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

    # Object that failed verification.
    #
    def object
      @context[:object]
    end

    def contextual_message
      <<~MESSAGE
        Verification failed for the following data:

        #{indent_as_code(JSON.pretty_generate(object))}

        Here's a list of failures:

        #{indent_as_code(JSON.pretty_generate(verifier.messages))}
      MESSAGE
    end
  end

  class UnknownCommand < Error
    MESSAGES = {
      default: "`{command}' is not a known command"
    }.freeze
  end

  class UnknownHelperContext < Error
    MESSAGES = {
      default: "`{context}' is not a known helper context"
    }.freeze
  end

  class UnknownType < Error
    MESSAGES = {
      default: "`{type}' is not a known type"
    }.freeze

    def contextual_message
      known_types = @context[:types].each_with_object(String.new) { |known_type, known_types_message|
        known_types_message << "  - #{known_type.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these known types:

        #{known_types}
      MESSAGE
    end
  end

  class UnknownPlugin < Error
    MESSAGES = {
      default: "`{plugin}' is not a known plugin"
    }.freeze

    def contextual_message
      available_plugins = Pakyow.plugins.keys.each_with_object(String.new) { |plugin_name, available_plugins_message|
        available_plugins_message << "  - #{plugin_name.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these available plugins:

        #{available_plugins}
      MESSAGE
    end
  end

  class UnknownValidationError < Error
  end
end
