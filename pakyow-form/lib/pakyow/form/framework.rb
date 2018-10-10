# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  module Form
    class Framework < Pakyow::Framework(:form)
      def boot
        object.class_eval do
          isolated :Controller do
            allow_params :form

            action :clear_form_errors
            private def clear_form_errors
              if params.include?(:form)
                data.ephemeral(:errors, form_id: params[:form][:id]).set([])
              end
            end
          end

          handle InvalidData, as: :bad_request do |error|
            if params.include?(:form)
              errors = error.verifier.messages.flat_map { |_type, field_messages|
                field_messages.flat_map { |field, messages|
                  messages.map { |message|
                    { field: field, message: "#{Support.inflector.humanize(field)} #{message}" }
                  }
                }
              }

              if app.class.includes_framework?(:ui) && ui?
                data.ephemeral(:errors, form_id: params[:form][:id]).set(errors)
              else
                connection.set :__form_errors, errors

                # Expose submitted values to be presented in the form.
                #
                params.reject { |key| key == :form }.each do |key, value|
                  expose key, value, for: params[:form][:binding].to_s.split(":", 2)[1]
                end

                reroute params[:form][:origin], method: :get, as: :bad_request
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

              expose :form_binding, params.dig(:form, :binding)
              expose :form_errors, data.ephemeral(:errors, form_id: connection.get(:__form_ids).shift).set(errors)
            end

            presenter do
              def perform
                if form_binding.nil? || form_binding == view.channeled_binding_name
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
                errored_fields = form_errors.map { |error|
                  error[:field]
                }

                view.binding_props.map { |prop|
                  prop.label(:binding)
                }.each do |binding_name|
                  if errored_fields.include?(binding_name)
                    find(binding_name).attrs[:class] << :errored
                  else
                    find(binding_name).attrs[:class].delete(:errored)
                  end
                end
              end

              def present_errors(errors)
                find(:error) do |view|
                  view.present(errors)
                end
              end
            end
          end
        end
      end
    end
  end
end
