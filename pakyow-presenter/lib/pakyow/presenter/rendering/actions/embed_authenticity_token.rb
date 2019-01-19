# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class EmbedAuthenticityToken
        def call(renderer)
          if renderer.connection.app.config.presenter.embed_authenticity_token
            if head = renderer.presenter.view.object.find_significant_nodes(:head)[0]
              # embed the authenticity token
              head.append("<meta name=\"pw-authenticity-token\" content=\"#{renderer.connection.verifier.sign(renderer.authenticity_client_id)}\">\n")

              # embed the parameter name the token should be submitted as
              head.append("<meta name=\"pw-authenticity-param\" content=\"#{renderer.connection.app.config.security.csrf.param}\">\n")
            end
          end
        end
      end
    end
  end
end
