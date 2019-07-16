# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/reflection/builders/source"
require "pakyow/reflection/builders/endpoints"
require "pakyow/reflection/builders/actions"

module Pakyow
  module Reflection
    module Config
      extend Support::Extension

      apply_extension do
        configurable :reflection do
          setting :builders, {
            source: Builders::Source,
            endpoints: Builders::Endpoints,
            actions: Builders::Actions
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
