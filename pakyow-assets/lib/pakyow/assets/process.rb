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

      def watch_callback(_modified, added, removed)
        if (added + removed).find { |path| Assets.extensions.include?(File.extname(path)) }
          @app.build_packs
          restart
        end
      end
    end
  end
end
