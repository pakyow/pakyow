# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Initializing
        extend Support::Extension

        apply_extension do
          after :initialize do
            state_for(:templates) << Templates.new(
              :default,
              config.presenter.path,
              processor: ProcessorCaller.new(
                self.class.state[:processor].instances
              )
            )

            state_for(:templates) << Templates.new(:errors, File.join(File.expand_path("../../../", __FILE__), "views", "errors"))
          end
        end
      end
    end
  end
end
