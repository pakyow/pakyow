# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  module Behavior
    module Sessions
      extend Support::Extension

      apply_extension do
        attr_reader :session_object, :session_options

        after "configure" do
          if config.session.enabled
            require "pakyow/app/connection/session/#{config.session.object}"

            @session_object = Pakyow::App::Connection::Session.const_get(
              Support.inflector.classify(config.session.object)
            )

            @session_options = if config.session.respond_to?(config.session.object)
              config.session.public_send(config.session.object)
            else
              {}
            end
          end
        rescue LoadError => error
          # TODO: Improve this with a specific "session object missing" error.
          #
          raise error
        end
      end
    end
  end
end
