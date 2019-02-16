# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module AuthenticityRendering
        extend Support::Extension

        apply_extension do
          post_process do |html|
            html.sub!("{{pw-authenticity-token}}", @connection.verifier.sign(authenticity_client_id))
            html.sub!("{{pw-authenticity-param}}", @connection.app.config.security.csrf.param.to_s)
            html
          end
        end
      end
    end
  end
end
