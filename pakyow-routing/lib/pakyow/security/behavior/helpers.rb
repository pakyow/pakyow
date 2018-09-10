# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/security/helpers/csrf"

module Pakyow
  module Security
    module Behavior
      module Helpers
        extend Support::Extension

        apply_extension do
          helper :passive, Security::Helpers::CSRF
        end
      end
    end
  end
end
