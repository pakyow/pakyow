# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/routing/security/errors"

module Pakyow
  module Security
    module Behavior
      module Insecure
        extend Support::Extension

        apply_extension do
          handle InsecureRequest, as: 403 do
            trigger(403)
          end
        end
      end
    end
  end
end
