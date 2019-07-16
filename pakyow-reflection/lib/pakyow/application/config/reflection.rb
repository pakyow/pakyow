# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/reflection/builders/source"
require "pakyow/reflection/builders/endpoints"
require "pakyow/reflection/builders/actions"

module Pakyow
  class Application
    module Config
      module Reflection
        extend Support::Extension

        apply_extension do
          configurable :reflection do
            setting :builders, {
              source: Pakyow::Reflection::Builders::Source,
              endpoints: Pakyow::Reflection::Builders::Endpoints,
              actions: Pakyow::Reflection::Builders::Actions
            }

            setting :ignored_template_stores, [:errors]

            configurable :data do
              setting :connection, :default
            end
          end
        end
      end
    end
  end
end
