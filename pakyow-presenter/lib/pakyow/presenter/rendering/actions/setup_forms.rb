# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupForms
        def call(renderer)
          forms(renderer).each do |form|
            unless form.view.labeled?(:__form_setup)
              if object = object_for_form(form, renderer)
                setup_form_for_exposed_object(form, object)
              elsif form.view.labeled?(:binding)
                case renderer.connection.get(:__endpoint_name)
                when :new
                  form.create
                when :edit
                  form.update(renderer.connection.params)
                else
                  form.create
                end
              end
            end

            setup_form_id(form)

            unless form.view.labeled?(:__form_embed)
              setup_metadata(form, renderer)

              if renderer.connection.app.config.presenter.embed_authenticity_token
                setup_authenticity_token(form, renderer)
              end

              form.view.object.set_label(:__form_embed, true)
            end
          end
        end

        private

        def forms(renderer)
          [].tap do |forms|
            if renderer.presenter.view.object.is_a?(StringDoc::Node) && renderer.presenter.view.form?
              forms << renderer.presenter.presenter_for(
                renderer.presenter.view, type: FormPresenter
              )
            end

            forms.concat(renderer.presenter.forms)
          end
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

        def setup_form_id(form)
          form.view.label(:metadata)[:id] ||= SecureRandom.hex(24)

          unless form.view.labeled?(FormPresenter::ID_LABEL)
            form.view.object.set_label(FormPresenter::ID_LABEL, form.view.label(:metadata)[:id])
          end
        end
      end
    end
  end
end
