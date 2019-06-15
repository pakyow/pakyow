# frozen_string_literal: true

require "json"

require "pakyow/framework"

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  module Form
    module ConnectionHelpers
      def form
        get(:__form)
      end
    end

    class Framework < Pakyow::Framework(:form)
      def boot
        object.class_eval do
          isolated :Controller do
            action :clear_form_errors do
              if connection.form
                data.ephemeral(:errors, form_id: connection.form[:id]).set([])
              end
            end
          end

          isolated :Connection do
            include ConnectionHelpers
          end

          handle InvalidData, as: :bad_request do |error|
            if connection.form
              errors = error.result.messages.flat_map { |type, messages|
                case messages
                when Array
                  messages.map { |type_message|
                    { field: type, message: "#{Support.inflector.humanize(type)} #{type_message}" }
                  }
                when Hash
                  messages.flat_map { |field, field_messages|
                    field_messages.map { |field_message|
                      { field: field, message: "#{Support.inflector.humanize(field)} #{field_message}" }
                    }
                  }
                end
              }

              if app.class.includes_framework?(:ui) && ui?
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

          component :form do
            def perform
              errors = if connection.values.include?(:__form_errors)
                connection.get(:__form_errors)
              else
                []
              end

              form_id = connection.get(:__form).to_h[:id] || SecureRandom.hex(24)

              expose :form_id, form_id
              expose :form_binding, connection.form.to_h[:binding]
              expose :form_origin, connection.form.to_h[:origin] || connection.fullpath
              expose :form_errors, data.ephemeral(:errors, form_id: form_id).set(errors)

              # Expose submitted values to be presented in the form.
              #
              connection.get(:__form_values).to_h.each do |key, value|
                expose key, value, for: connection.form[:binding].to_s.split(":", 2)[1]
              end
            end

            presenter do
              render do
                view.label(:form)[:id] = form_id
                view.label(:form)[:binding] = form_binding || [
                  view.label(:binding)
                ].concat(view.label(:channel)).join(":")
                view.label(:form)[:origin] = form_origin

                if form_binding.nil? || form_binding.to_sym == view.channeled_binding_name
                  classify_form
                  classify_fields
                  present_errors(form_errors)
                end
              end

              private

              def classify_form
                if form_errors.any?
                  attrs[:class] << :errored
                else
                  attrs[:class].delete(:errored)
                end
              end

              def classify_fields
                view.each_binding_prop do |node|
                  binding_name = node.label(:binding)
                  error = form_errors.find { |e| e[:field] == binding_name }

                  find(binding_name).with do |field|
                    if error.nil?
                      field.attrs[:class].delete(:errored)
                      field.attrs[:title] = ""
                    else
                      field.attrs[:class] << :errored
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
