# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupForms
        def initialize(_options)
        end

        def call(renderer)
          form_ids = []
          renderer.presenter.forms.each do |form|
            setup_form(form, renderer)

            # FIXME: I don't like this, but unsure of a better way to make the
            # form id available to the form component; needs more thought
            #
            if form.view.object.significant?(:component)
              form_ids << form.view.object.label(FormPresenter::ID_LABEL)
            end
          end

          renderer.connection.set(:__form_ids, form_ids)
        end

        private

        def setup_form(form, renderer)
          setup_id(form, renderer)
          setup_origin(form, renderer)

          if renderer.connection.app.config.presenter.embed_authenticity_token
            setup_authenticity_token(form, renderer)
          end

          if object = object_for_form(form, renderer)
            setup_form_for_exposed_object(form, object)
          elsif endpoint = form.view.label(:endpoint)
            form.action = endpoint
          elsif form.view.labeled?(:binding)
            case renderer.connection.env["pakyow.endpoint.name"]
            when :new
              form.create({})
            when :edit
              form.update(renderer.connection.params)
            else
              form.create({})
            end
          end
        end

        def setup_id(form, renderer)
          if form_id = renderer.connection.params.dig(:form, :id)
            form.view.object.set_label(FormPresenter::ID_LABEL, form_id)
          end
        end

        def setup_origin(form, renderer)
          form.embed_origin(renderer.connection.params.dig(:form, :origin) || renderer.connection.fullpath)
        end

        def setup_authenticity_token(form, renderer)
          digest = Support::MessageVerifier.digest(
            form.id, key: renderer.authenticity_server_id
          )

          form.embed_authenticity_token(
            "#{form.id}:#{digest}",
            param: renderer.connection.app.config.security.csrf.param
          )
        end

        def setup_form_for_exposed_object(form, object)
          if form.view.label(:endpoint)
            form.setup(object)
          else
            if object.key?(:id)
              form.update(object)
            else
              form.create(object)
            end
          end
        end

        def object_for_form(form, renderer)
          if form_binding_name = form.view.label(:binding)
            renderer.connection.get([form_binding_name].concat(form.view.label(:channel)).join(":"))
          end
        end
      end
    end
  end
end
