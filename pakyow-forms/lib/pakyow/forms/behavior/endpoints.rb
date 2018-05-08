# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Forms
    module Behavior
      module Endpoints
        extend Support::Extension

        prepend_methods do
          def setup_form(action, object)
            super

            self.action = form_action(action, object)
          end
        end

        def form_action(action, object)
          if endpoint_state_defined?
            plural_name = Support.inflector.pluralize(@view.label(:binding)).to_sym
            @endpoints.path_to(plural_name, action, **form_action_params(object))
          end
        end

        def form_action_params(object)
          {}.tap do |params|
            params[:id] = object[:id] if object
          end
        end
      end
    end
  end
end
