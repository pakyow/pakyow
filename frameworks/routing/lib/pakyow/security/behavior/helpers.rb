# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../helpers/csrf"

module Pakyow
  module Security
    module Behavior
      module Helpers
        extend Support::Extension

        apply_extension do
          register_helper :passive, Security::Helpers::CSRF
        end
      end
    end
  end
end
