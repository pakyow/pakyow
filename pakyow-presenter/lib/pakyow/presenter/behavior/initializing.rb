# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/plugin"

module Pakyow
  module Presenter
    module Behavior
      module Initializing
        extend Support::Extension

        apply_extension do
          unless ancestors.include?(Plugin)
            after :initialize do
              state(:templates) << Templates.new(
                :default,
                config.presenter.path,
                processor: ProcessorCaller.new(
                  state(:processor)
                )
              )

              state(:templates) << Templates.new(:errors, File.join(File.expand_path("../../../", __FILE__), "views", "errors"))

              # Load plugin frontend after the app so that app has priority.
              #
              @plugs.each(&:load_frontend)
            end
          end
        end
      end
    end
  end
end
