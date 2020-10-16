# frozen_string_literal: true

require "json"

require_relative "error"

module Pakyow
  class EnvironmentError < Error
  end

  class ApplicationError < Error
  end

  class FormationError < Error
    class_state :messages, default: {
      missing: "`{formation}' is an invalid formation because it defines a top-level container ({container}) that doesn't exist",
      multiple: "`{formation}' is an invalid formation because it defines multiple top-level containers ({containers})"
    }.freeze
  end

  class RequestTooLarge < Error
    class_state :messages, default: {
      default: "Request length `{length}' exceeds the defined limit of `{limit}'"
    }
  end

  class InvalidData < Error
    class_state :messages, default: {
      verification: "Provided data didn't pass verification"
    }.freeze

    # Failed verifier result.
    #
    def result
      @context[:result]
    end

    # Object that failed verification.
    #
    def object
      @context[:object]
    end

    def contextual_message
      <<~MESSAGE
        Here's the data:

        #{indent_as_code(JSON.pretty_generate(object))}

        And here are the failures:

        #{indent_as_code(JSON.pretty_generate(result.messages))}
      MESSAGE
    end
  end

  class UnknownCommand < Error
    class_state :messages, default: {
      default: "`{command}' is not a known command",
      not_in_project_context: "Cannot run command `{command}' outside of a pakyow project",
      not_in_global_context: "Cannot run command `{command}' within a pakyow project"
    }.freeze
  end

  class UnknownFramework < Error
    class_state :messages, default: {
      default: "`{framework}' is not a known framework"
    }.freeze
  end

  class UnknownHelperContext < Error
    class_state :messages, default: {
      default: "`{context}' is not a known helper context"
    }.freeze
  end

  class UnknownType < Error
    class_state :messages, default: {
      default: "`{type}' is not a known type"
    }.freeze

    def contextual_message
      known_types = @context[:types].each_with_object(+"") { |known_type, known_types_message|
        known_types_message << "  - #{known_type.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these known types:

        #{known_types}
      MESSAGE
    end
  end

  class UnknownPlugin < Error
    class_state :messages, default: {
      default: "`{plugin}' is not a known plugin"
    }.freeze

    def contextual_message
      available_plugins = Pakyow.plugins.keys.each_with_object(+"") { |plugin_name, available_plugins_message|
        available_plugins_message << "  - #{plugin_name.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these available plugins:

        #{available_plugins}
      MESSAGE
    end
  end

  class UnknownValidationError < Error
    class_state :messages, default: {
      default: "`{validation}' is not a known validation"
    }.freeze
  end

  class UnknownService < Error
    class_state :messages, default: {
      default: "`{service}' is not a known service in the `{container}' container"
    }.freeze

    def contextual_message
      available_services = @context.services.each.each_with_object(+"") { |service, available_services_message|
        available_services_message << "  - #{service.object_name.name.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these available services:

        #{available_services}
      MESSAGE
    end
  end

  class UnknownContainerStrategy < Error
    class_state :messages, default: {
      default: "`{strategy}' is not a known container strategy"
    }.freeze
  end

  class UnknownReleaseChannel < Error
    class_state :messages, default: {
      default: "`{channel}' is not a known release channel"
    }.freeze

    def contextual_message
      release_channels = @context.release_channels.each_with_object(+"") { |channel, release_channels_message|
        release_channels_message << "  - #{channel.inspect}\n"
      }

      <<~MESSAGE
        Try using one of these available release channels:

        #{release_channels}
      MESSAGE
    end
  end
end
