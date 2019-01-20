# frozen_string_literal: true

require "base64"
require "json"

module Pakyow
  module Presenter
    module Actions
      # @api private
      class EmbedFormMetadata
        def call(renderer)
          renderer.presenter.forms.each do |form|
            setup_metadata(form, renderer)

            if renderer.connection.app.config.presenter.embed_authenticity_token
              setup_authenticity_token(form, renderer)
            end
          end
        end

        def setup_metadata(form, renderer)
          form.embed_metadata(
            renderer.connection.verifier.sign(
              form.view.label(:metadata).to_json
            )
          )
        end

        def setup_authenticity_token(form, renderer)
          form.embed_authenticity_token(
            renderer.connection.verifier.sign(form.id),
            param: renderer.connection.app.config.security.csrf.param
          )
        end
      end
    end
  end
end
