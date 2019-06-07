# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Behavior
      # Sets up the timezone for the environment.
      #
      module Timezone
        extend Support::Extension

        apply_extension do
          after "configure" do
            ENV["TZ"] = config.timezone.to_s
          end
        end
      end
    end
  end
end
