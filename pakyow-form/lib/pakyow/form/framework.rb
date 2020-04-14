# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Form
    class Framework < Pakyow::Framework(:form)
      def boot
        require "json"

        require "pakyow/support/extension"
        require "pakyow/support/inflector"

        require_relative "../application/connection/helpers/form"

        object.class_eval do
          isolated :Controller do
            # Clear form errors after a successful submission.
            #
            after "dispatch" do
              if connection.form && connection.status < 400
                data.ephemeral(:errors, form_id: connection.form[:id]).set([])
              end
            end

            handle InvalidData, as: :bad_request do |error, connection:|
              if connection.form && connection.form.include?(:origin)
                raw_messages = case error.result
                when Verifier::Result
                  error.result.messages(type: :presentable)
                else
                  error.result.messages
                end

                errors = case raw_messages
                when Array
                  raw_messages.map { |message|
                    { message: message }
                  }
                when Hash
                  raw_messages.flat_map { |type, messages|
                    case messages
                    when Array
                      messages.map { |type_message|
                        { field: type, message: type_message }
                      }
                    when Hash
                      messages.flat_map { |field, field_messages|
                        field_messages.map { |field_message|
                          { field: field, message: field_message }
                        }
                      }
                    end
                  }
                end

                if connection.app.class.includes_framework?(:ui) && ui?
                  data.ephemeral(:errors, form_id: connection.form[:id]).set(errors)
                else
                  connection.set(:__form_errors, errors)
                  connection.set(:__form_values, params.reject { |key| key == :form })
                  reroute connection.form[:origin], method: :get, as: :bad_request
                end
              else
                reject
              end
            end
          end

          isolated :Connection do
            include Pakyow::Application::Connection::Helpers::Form
          end

          component :form do
            def perform
              errors = if connection.values.include?(:__form_errors)
                connection.get(:__form_errors)
              else
                []
              end

              # We have to take over the management of form ids from presenter for error handling.
              # If we're re-rendering a submitted form we reuse the id, otherwise create a new one.
              #
              form_id = if connection.form
                connection.form[:id]
              else
                SecureRandom.hex(24)
              end

              expose :form_id, form_id

              # Relate ephemeral errors to the form id.
              #
              expose :form_errors, data.ephemeral(:errors, form_id: form_id).set(errors)

              # Expose submitted values to be presented in the form.
              #
              connection.get(:__form_values).to_h.each do |key, value|
                expose connection.form[:binding], value
              end
            end

            presenter do
              render do
                view.label(:form)[:id] = form_id
                presented_form_binding = presentables.dig(:__form, :binding)
                if presented_form_binding.nil? || presented_form_binding.to_sym == view.channeled_binding_name
                  classify_form; classify_fields
                  present_errors(form_errors)
                end
              end

              private

              def classify_form
                if form_errors.any?
                  attrs[:class] << :"ui-errored"
                else
                  attrs[:class].delete(:"ui-errored")
                end
              end

              def classify_fields
                view.each_binding_prop do |node|
                  binding_name = node.label(:binding)
                  error = form_errors.find { |e| e[:field] == binding_name }

                  find(binding_name).with do |field|
                    if error.nil?
                      field.attrs[:class].delete(:"ui-errored")
                      field.attrs[:title] = ""
                    else
                      field.attrs[:class] << :"ui-errored"
                      field.attrs[:title] = error[:message]
                    end
                  end
                end
              end

              def present_errors(errors)
                if form_errors_presenter = component(:"form-errors")
                  if error_presenter = form_errors_presenter.find(:error)
                    error_presenter.present(errors)
                  end

                  if errors.empty?
                    form_errors_presenter.attrs[:class] << :"ui-hidden"
                  else
                    form_errors_presenter.attrs[:class].delete(:"ui-hidden")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
