# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Watching
        extend Support::Extension

        apply_extension do
          after :load do
            ([:html] + self.class.state[:processor].instances.map(&:extensions).flatten).uniq.each do |extension|
              config.process.watched_paths << File.join(config.presenter.path, "**/*.#{extension}")
            end
          end
        end
      end
    end
  end
end
