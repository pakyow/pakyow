# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Initializers
      extend Support::Extension

      apply_extension do
        after :make do
          Dir.glob(File.join(config.root, "config/initializers/application/**/*.rb")).each do |initializer|
            class_eval(File.read(initializer), initializer)
          end
        end
      end
    end
  end
end
