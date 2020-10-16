# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"
require "pakyow/support/safe_string"

require_relative "../../presenters/form"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module SetupForms
          extend Support::Extension

          apply_extension do
            build do |view, app:|
              SetupForms.build(view, app)
            end

            attach do |presenter, app:|
              SetupForms.attach(presenter, app)
            end

            expose do |connection|
              connection.set(:__params, connection.params)
              connection.set(:__endpoint, connection.endpoint)
              connection.set(:__verifier, connection.verifier)

              origin = if connection.set?(:__form)
                connection.get(:__form)[:origin]
              else
                connection.fullpath
              end

              connection.set(:__origin, origin)
            end
          end

          # @api private
          def self.build(view, app)
            forms = view.forms
            if !view.object.is_a?(StringDoc) && view.object.significant?(:form)
              forms << view
            end

            forms.each do |form|
              # Allows app renders to set metadata values on forms.
              #
              form.object.set_label(:form, {})

              # Set the form id.
              #
              form_id = SecureRandom.hex(24)
              form.object.label(:form)[:id] = form_id
              form.object.set_label(Presenters::Form::ID_LABEL, form_id)

              # Set the form binding.
              #
              form.object.label(:form)[:binding] = form.object.label(:channeled_binding)

              # Setup field names.
              #
              form.object.children.each_significant_node(:binding) do |binding_node|
                if Pakyow::Presenter::Views::Form::FIELD_TAGS.include?(binding_node.tagname)
                  if binding_node.attributes[:name].to_s.empty?
                    binding_node.attributes[:name] = "#{form.object.label(:binding)}[#{binding_node.label(:binding)}]"
                  end

                  if binding_node.tagname == "select" && binding_node.attributes[:multiple]
                    Presenters::Form.pluralize_field_name(binding_node)
                  end
                end
              end

              # Connect labels.
              #
              form.object.children.each_significant_node(:label) do |label_node|
                if label_node.attributes[:for] && (input = form.find(*label_node.attributes[:for].to_s.split(".")))
                  Presenters::Form.connect_input_to_label(input, label_node)
                end
              end

              form.prepend(
                Support::SafeStringHelpers.html_safe(
                  "<input type=\"hidden\" name=\"pw-http-method\">"
                )
              )

              form.prepend(
                Support::SafeStringHelpers.html_safe(
                  "<input type=\"hidden\" name=\"pw-form\">"
                )
              )

              if app.config.presenter.embed_authenticity_token
                form.prepend(
                  Support::SafeStringHelpers.html_safe(
                    "<input type=\"hidden\" name=\"#{app.config.security.csrf.param}\">"
                  )
                )
              end
            end
          end

          # @api private
          def self.attach(presenter, app)
            presenter.render node: -> {
              forms = self.forms
              if !object.is_a?(StringDoc) && object.significant?(:form)
                forms << self
              end

              forms
            } do
              unless setup?
                if (object = object_for_form)
                  if app.includes_framework?(:data) && object.is_a?(Data::Proxy)
                    object = object.one
                  end
                end

                if !object.nil?
                  if labeled?(:endpoint)
                    setup(object)
                  elsif object.key?(:id)
                    update(object)
                  else
                    create(object)
                  end
                elsif labeled?(:binding)
                  case presentables[:__endpoint_name]
                  when :edit
                    update(
                      __endpoint.params.each_with_object({}) { |(key, _), passed_params|
                        key = key.to_sym
                        passed_params[key] = __params[key]
                      }
                    )
                  else
                    create
                  end
                end
              end

              view.object.label(:form)[:origin] = presentables[:__origin]

              node = view.object.each_significant_node(:field).find { |field_node|
                field_node.attributes[:name] == "pw-form"
              }

              unless node.nil?
                node.attributes[:value] = presentables[:__verifier].sign(
                  label(:form).to_json
                )
              end
            end

            presenter.render node: -> {
              stringified_param = app.config.security.csrf.param.to_s
              node = object.each_significant_node(:field, descend: true).find { |field_node|
                field_node.attributes[:name] == stringified_param
              }

              unless node.nil?
                View.from_object(node)
              end
            } do
              attributes[:value] = presentables[:__verifier].sign(Support::MessageVerifier.key)
            end

            presenter.render node: -> {
              object.each_significant_node(:method_override, descend: true).map { |node|
                View.from_object(node)
              }
            } do
              remove if attributes[:value].empty?
            end
          end
        end
      end
    end
  end
end
