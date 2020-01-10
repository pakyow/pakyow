# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module Watching
          extend Support::Extension

          apply_extension do
            after "load" do
              ([:html] + processors.each.map(&:extensions).flatten).uniq.each do |extension|
                config.process.watched_paths << File.join(config.presenter.path, "**/*.#{extension}")
              end
            end
          end
        end
      end
    end
  end
end
