# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Routing
        module Definition
          extend Support::Extension

          apply_extension do
            include Methods
            extend Methods
          end

          module Methods
            # Defines a RESTful resource.
            #
            # @see Routing::Extension::Resource
            #
            def resource(name, path, *args, param: Pakyow::Routing::Extension::Resource::DEFAULT_PARAM, &block)
              controller name, path, *args do
                expand_within(:resource, param: param, &block)
              end
            end
          end
        end
      end
    end
  end
end
