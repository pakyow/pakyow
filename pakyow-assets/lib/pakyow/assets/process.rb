# frozen_string_literal: true

require "pakyow/process"

module Pakyow
  module Assets
    class Process < Process
      def initialize(server, app)
        super(server)
        @app = app
      end

      def start
        # TODO: or, start the webpack-dev-server based on the config options
        @pid = ::Process.spawn("./node_modules/.bin/webpack --config config/assets/environment.js --watch", out: File.open(File::NULL, "w"), err: $stderr)
      end

      def watch_callback(modified, added, removed)
        if restart?(modified, added, removed)
          @app.build_packs
          restart
        end
      end

      def restart?(modified, added, removed)
        return true if (added + removed).find { |path|
          Assets.extensions.include?(File.extname(path))
        }

        expanded_presenter_path = File.expand_path(@app.config.presenter.path)
        return true if modified.find { |path|
          !Assets.extensions.include?(File.extname(path)) && File.expand_path(path).start_with?(expanded_presenter_path)
        }

        false
      end
    end
  end
end
