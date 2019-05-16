# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"
require "pakyow/support/safe_string"

require "pakyow/presenter/presenters/form"

module Pakyow
  module Presenter
    module Actions
      module SetupForms
        extend Support::Extension

        apply_extension do
          build do |view, app:|
            view.forms.each do |form|
              # Allows app renders to set metadata values on forms.
              #
              # TODO: name this `form_metadata`, or make `metadata` a global label value and namespace under `form`
              form.object.set_label(:metadata, {})

              # Set the form id.
              #
              form_id = SecureRandom.hex(24)
              form.object.label(:metadata)[:id] = form_id
              form.object.set_label(Presenters::Form::ID_LABEL, form_id)

              # Setup field names.
              #
              form.object.children.each_significant_node_without_descending(:binding) do |binding_node|
                if Pakyow::Presenter::Form::FIELD_TAGS.include?(binding_node.tagname)
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
              form.object.children.each_significant_node_without_descending(:label) do |label_node|
                if label_node.attributes[:for] && input = form.find(*label_node.attributes[:for].to_s.split("."))
                  Presenters::Form.connect_input_to_label(input, label_node)
                end
              end

              form.prepend(
                Support::SafeStringHelpers.safe(
                  "<input type=\"hidden\" name=\"_method\">"
                )
              )

              form.prepend(
                Support::SafeStringHelpers.safe(
                  "<input type=\"hidden\" name=\"_form\">"
                )
              )

              if app.config.presenter.embed_authenticity_token
                form.prepend(
                  Support::SafeStringHelpers.safe(
                    "<input type=\"hidden\" name=\"#{app.config.security.csrf.param}\">"
                  )
                )
              end
            end
          end

          attach do |presenter, app:|
            presenter.render node: -> { forms } do
              unless setup?
                if object = object_for_form
                  if labeled?(:endpoint)
                    setup(object)
                  else
                    if object.key?(:id)
                      update(object)
                    else
                      create(object)
                    end
                  end
                elsif labeled?(:binding)
                  case presentables[:__endpoint_name]
                  when :edit
                    update(
                      __endpoint.params.each_with_object({}) { |(key, _), passed_params|
                        passed_params[key] = __params[key]
                      }
                    )
                  else
                    create
                  end
                end
              end

              node = view.object.each_significant_node(:field).find { |field_node|
                field_node.attributes[:name] == "_form"
              }

              unless node.nil?
                node.attributes[:value] = presentables[:__verifier].sign(
                  label(:metadata).to_json
                )
              end
            end

            presenter.render node: -> {
              stringified_param = app.config.security.csrf.param.to_s
              node = object.each_significant_node(:field).find { |field_node|
                field_node.attributes[:name] == stringified_param
              }

              unless node.nil?
                View.from_object(node)
              end
            } do
              attributes[:value] = presentables[:__verifier].sign(Support::MessageVerifier.key)
            end

            presenter.render node: -> {
              object.each_significant_node(:method_override).map { |node|
                View.from_object(node)
              }
            } do
              remove if attributes[:value].empty?
            end
          end

          expose do |connection|
            connection.set(:__params, connection.params)
            connection.set(:__endpoint, connection.endpoint)
            connection.set(:__verifier, connection.verifier)
          end
        end
      end
    end
  end
end
