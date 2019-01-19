# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupFormMeta
        def call(renderer)
          form_ids = []

          renderer.presenter.forms.each do |form|
            setup_id(form, renderer)
            setup_origin(form, renderer)

            if renderer.connection.app.config.presenter.embed_authenticity_token
              setup_authenticity_token(form, renderer)
            end

            if form.view.object.significant?(:component)
              form_ids << form.view.object.label(FormPresenter::ID_LABEL)
            end
          end

          renderer.connection.set(:__form_ids, form_ids)
        end

        def setup_id(form, renderer)
          form_id = renderer.connection.params.dig(:form, :id) || SecureRandom.hex(24)
          form.view.object.set_label(FormPresenter::ID_LABEL, form_id)
          form.embed_id(form_id)
        end

        def setup_origin(form, renderer)
          form.embed_origin(renderer.connection.params.dig(:form, :origin) || renderer.connection.fullpath)
        end

        def setup_authenticity_token(form, renderer)
          form.embed_authenticity_token(
            Support::MessageVerifier.sign(form.id, key: renderer.authenticity_server_id),
            param: renderer.connection.app.config.security.csrf.param
          )
        end
      end
    end
  end
end
