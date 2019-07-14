# frozen_string_literal: true

require "pakyow/presenter/presenter"
require "pakyow/presenter/presenters/form"

module Pakyow
  module Presenter
    module Presenters
      class Endpoint < DelegateClass(Presenter)
        def setup
          setup_endpoint(path: endpoint_path, method: endpoint_method)

          unless endpoint_method == :get
            setup_non_get_endpoint(path: endpoint_path, method: endpoint_method)
          end
        end

        # Fixes an issue using pp inside a delegator.
        #
        def pp(*args)
          Kernel.pp(*args)
        end

        # Delegate private methods.
        #
        def method_missing(method_name, *args, &block)
          __getobj__.send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          super || __getobj__.respond_to?(method_name, true)
        end

        private

        def endpoint_method
          if view.object.labeled?(:endpoint_object)
            view.object.label(:endpoint_object).method
          else
            :get
          end
        end

        def endpoint_path
          if Pakyow.env?(:prototype)
            case view.object.tagname
            when "a"
              view.attrs[:href].to_s
            when "form"
              view.attrs[:action].to_s
            else
              nil
            end
          elsif view.object.labeled?(:endpoint_object)
            view.object.label(:endpoint_object).path(
              __endpoint.params.merge(view.object.label(:endpoint_params).to_h)
            )
          else
            nil
          end
        end

        def setup_endpoint(path:, method:)
          endpoint_action_presenter = endpoint_action
          case endpoint_action_presenter.object.tagname
          when "a"
            if path && !Pakyow.env?(:prototype)
              endpoint_action_presenter.attributes[:href] = path
            end

            if endpoint_action_presenter.attributes.has?(:href)
              endpoint_path = __endpoint[:path].to_s
              if endpoint_path == endpoint_action_presenter.attributes[:href]
                attributes[:class].add(:"ui-current")
              elsif endpoint_path.start_with?(endpoint_action_presenter.attributes[:href])
                attributes[:class].add(:"ui-active")
              end
            end
          when "form"
            form_presenter = Form.new(__getobj__)
            form_presenter.action = path
            form_presenter.method = method
          end
        end

        def setup_non_get_endpoint(path:, method:)
          unless object.tagname == "form"
            object.attributes.delete(:"data-e")

            if object.tagname == "a"
              object.attributes[:href] = "javascript:void(0)"
            end

            # FIXME: Everything below could probably be streamlined and improved. Some ideas:
            #
            #   * Build the form once, then attach a render that fills in the dynamic parts.
            #   * Define the presenter class once, attached to the view in step one.
            #   * Continue replacing with a string but all we'd be doing is building the string.
            #
            form_node = StringDoc.new(
              <<~HTML
                <form action="#{path}" method="post">
                  <input type="hidden" name="pw-http-method" value="#{method}">
                  #{object.render}
                </form>
              HTML
            ).nodes[0]

            form_view = View.from_object(form_node)
            Renderer::Behavior::SetupForms.build(form_view, __getobj__.app)

            presenter_class = Class.new(Presenter)
            Renderer::Behavior::SetupForms.attach(presenter_class, __getobj__.app)

            presenter_class.attach(form_view)
            form_presenter = presenter_class.new(form_view, app: __getobj__.app, presentables: __getobj__.presentables)
            replace(html_safe(form_presenter.to_html))
          end
        end

        class << self
          # Recursively attach to binding endpoints.
          #
          # @api private
          def attach_to_node(node, renders, binding_path: [])
            node.each_significant_node(:binding) do |binding_node|
              next_binding_path = binding_path.dup
              if binding_node.significant?(:binding_within)
                next_binding_path << binding_node.label(:channeled_binding)
              end

              current_binding_path = binding_path.dup
              current_binding_path << binding_node.label(:channeled_binding)

              if binding_node.significant?(:endpoint)
                renders << {
                  binding_path: current_binding_path,
                  priority: :low,
                  block: Proc.new {
                    setup
                  }
                }
              else
                binding_node.find_significant_nodes(:endpoint).each do |endpoint_node|
                  renders << {
                    binding_path: current_binding_path,
                    priority: :low,
                    block: Proc.new {
                      endpoint_view = endpoint(endpoint_node.label(:endpoint))
                      case endpoint_view
                      when Presenters::Form
                        Presenters::Endpoint.new(endpoint_view.__getobj__).setup
                      when Presenters::Endpoint
                        endpoint_view.setup
                      end
                    }
                  }
                end
              end

              attach_to_node(binding_node, renders, binding_path: next_binding_path)
            end
          end
        end
      end
    end
  end
end
