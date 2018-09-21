# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/plugin"

module Pakyow
  module Presenter
    module Behavior
      module Initializing
        extend Support::Extension

        apply_extension do
          after :initialize do
            if is_a?(Plugin)
              @app.after :initialize, priority: :low, exec: false do
                load_frontend
              end
            else
              state(:templates) << Templates.new(
                :default,
                config.presenter.path,
                processor: ProcessorCaller.new(
                  state(:processor)
                )
              )
            end

            state(:templates) << Templates.new(:errors, File.join(File.expand_path("../../../", __FILE__), "views", "errors"))
          end
        end
      end
    end
  end
end
