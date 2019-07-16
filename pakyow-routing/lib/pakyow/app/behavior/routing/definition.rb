# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
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

            # Registers an error handler automatically available in all Controller instances.
            #
            # @see Routing::Behavior::ErrorHandling#handle
            def handle(name_exception_or_code, as: nil, &block)
              const_get(:Controller).handle(name_exception_or_code, as: as, &block)
            end
          end
        end
      end
    end
  end
end
