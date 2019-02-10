# frozen_string_literal: true

module Pakyow
  module Presenter
    module Behavior
      module AuthenticityRendering
        def to_html(*)
          super.tap do |html|
            html.sub!("{{pw-authenticity-token}}", @connection.verifier.sign(authenticity_client_id))
            html.sub!("{{pw-authenticity-param}}", @connection.app.config.security.csrf.param.to_s)
          end
        end
      end
    end
  end
end
