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
                    { message: "#{Support.inflector.humanize(field)} #{message}" }
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
                  expose key, value, for: :form
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

              expose :errors, data.ephemeral(:errors, form_id: connection.get(:__form_ids).shift).set(errors)
            end

            presenter do
              def perform
                classify_form
                present_errors
              end

              private

              def classify_form
                if errors.any?
                  attrs[:class] << :errored
                else
                  attrs[:class].delete(:errored)
                end
              end

              def present_errors
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
