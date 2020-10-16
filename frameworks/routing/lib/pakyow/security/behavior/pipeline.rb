# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Security
    module Behavior
      module Pipeline
        extend Support::Extension

        apply_extension do
          require "pakyow/security/pipelines/csrf"

          isolated :Controller do
            include_pipeline Pipelines::CSRF
          end
        end
      end
    end
  end
end
