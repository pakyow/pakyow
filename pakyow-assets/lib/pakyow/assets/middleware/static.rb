# frozen_string_literal: true

module Pakyow
  module Assets
    # Serves content from the configured public directory.
    #
    class Static
      def initialize(app)
        @app = app
      end

      def call(env)
        path = File.join(self.class.app.config.assets.local_public_path, env["PATH_INFO"])

        if path =~ /\.(.*)$/ && File.file?(path)
          headers = {
            "Content-Type" => Rack::Mime.mime_type(File.extname(path))
          }

          if self.class.app.config.assets.fingerprint
            mtime = File.mtime(path)
            headers["Age"] = (Time.now - mtime).to_i
            headers["Cache-Control"] = "public, max-age=31536000"
            headers["Vary"] = "Accept-Encoding"
            headers["Last-Modified"] = mtime.httpdate
          end

          [200, headers, File.open(path)]
        else
          @app.call(env)
        end
      end
    end
  end
end
