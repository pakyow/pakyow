# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class SetupFormObjects
        def call(renderer)
          renderer.presenter.forms.reject { |form|
            form.view.labeled?(:__form_setup)
          }.each do |form|
            if object = object_for_form(form, renderer)
              setup_form_for_exposed_object(form, object)
            elsif form.view.labeled?(:binding)
              case renderer.connection.env["pakyow.endpoint.name"]
              when :new
                form.create
              when :edit
                form.update(renderer.connection.params)
              else
                form.create
              end
            end
          end
        end

        private

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
