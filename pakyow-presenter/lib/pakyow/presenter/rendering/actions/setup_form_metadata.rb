# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupFormMetadata
        def call(renderer)
          form_ids = renderer.presenter.forms.each_with_object([]) { |form, ids|
            id = setup_form_id(form, renderer)
            if form.view.object.significant?(:component)
              ids << id
            end

            form.view.object.set_label(:authenticity_key, renderer.connection.verifier.key)

            if renderer.connection.app.config.presenter.embed_authenticity_token
              form.view.object.set_label(:authenticity_param, renderer.connection.app.config.security.csrf.param)
            end
          }

          renderer.connection.set(:__form_ids, form_ids)
        end

        def setup_form_id(form, renderer)
          (renderer.connection.get(:__form).to_h[:id] || SecureRandom.hex(24)).tap do |form_id|
            form.view.object.set_label(FormPresenter::ID_LABEL, form_id)
            form.view.object.set_label(:metadata, id: form_id)
          end
        end
      end
    end
  end
end
