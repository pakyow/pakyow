# frozen_string_literal: true

require "pakyow/support/isolable"

module Pakyow
  class Application
    module Behavior
      # Helps manage isolated classes for an app.
      #
      module Isolating
        extend Support::Extension

        apply_extension do
          include Support::Isolable
        end
      end
    end
  end
end
