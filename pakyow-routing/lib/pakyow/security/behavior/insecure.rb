# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../errors"

module Pakyow
  module Security
    module Behavior
      module Insecure
        extend Support::Extension

        apply_extension do
          isolated :Controller do
            handle InsecureRequest, as: 403
          end
        end
      end
    end
  end
end
