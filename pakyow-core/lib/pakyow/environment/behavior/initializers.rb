# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Initializers
      extend Support::Extension

      apply_extension do
        before :configure do
          Dir.glob(File.join(Pakyow.config.root, "config/initializers/environment/**/*.rb")).each do |initializer|
            require initializer
          end
        end
      end
    end
  end
end
