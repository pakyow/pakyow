# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Forms
    module Behavior
      module Setup
        extend Support::Extension

        apply_extension do
          after :initialize do
            setup_forms
          end
        end

        private

        def setup_forms
          @presenter.forms.each do |form|
            setup_id_for_form(form)
            setup_origin_for_form(form)

            if @connection.app.config.presenter.embed_authenticity_token
              setup_authenticity_token_for_form(form)
            end

            setup_form_for_exposed_object(form)
            # setup_form_errors(form)
          end
        end

        def setup_authenticity_token_for_form(form)
          digest = Support::MessageVerifier.digest(
            form.id, key: authenticity_server_id
          )

          form.embed_authenticity_token(
            "#{form.id}:#{digest}",
            param: @connection.app.config.csrf.param
          )
        end

        def setup_id_for_form(form)
          if form_id = @connection.params.dig(:form, :id)
            form.view.object.set_label(FormPresenter::ID_LABEL, form_id)
          end
        end

        def setup_origin_for_form(form)
          form.embed_origin(@connection.params.dig(:form, :origin) || @connection.fullpath)
        end

        def setup_form_for_exposed_object(form)
          case @connection.env["pakyow.endpoint.name"]
          when :new
            form.create(object_for_form(form) || {})
          when :edit
            if object = object_for_form(form)
              form.update(object)
            end
          end
        end

        # def setup_form_errors(form)
        #   if form_error_view = form.find(:error)
        #     if @connection.error
        #       messages = @connection.error.verifier.messages[form.view.label(:binding)].flat_map { |field, field_messages|
        #         field_messages.map { |field_message|
        #           "#{field} #{field_message}"
        #         }
        #       }

        #       form_error_view.find(:message).transform(messages) do |message_view, message|
        #         message_view.html = message.object
        #       end
        #     else
        #       # TODO: if data, do the ephemeral object
        #       form_error_view.remove
        #     end
        #   end
        # end

        def object_for_form(form)
          if form_binding_name = form.view.label(:binding)
            @connection.get("#{form_binding_name}:form")
          end
        end
      end
    end
  end
end
