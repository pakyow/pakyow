# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Prelaunching
        extend Support::Extension

        apply_extension do
          on "configure" do
            config.tasks.prelaunch << "assets:precompile"
          end
        end
      end
    end
  end
end
