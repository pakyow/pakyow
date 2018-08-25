# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupForms
        def initialize(_options)
        end

        def call(renderer)
          renderer.presenter.forms.each do |form|
            form.embed_origin(renderer.connection.fullpath)

            if renderer.connection.app.config.presenter.embed_authenticity_token
              digest = Support::MessageVerifier.digest(
                form.id, key: renderer.authenticity_server_id
              )

              form.embed_authenticity_token("#{form.id}:#{digest}", param: renderer.connection.app.config.security.csrf.param)
            end
          end
        end
      end
    end
  end
end
