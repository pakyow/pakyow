# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      module Initializers
        extend Support::Extension

        apply_extension do
          before :configure do
            Dir.glob(File.join(config.root, "config/initializers/application/**/*.rb")).each do |initializer|
              instance_eval(File.read(initializer), initializer)
            end
          end
        end
      end
    end
  end
end
