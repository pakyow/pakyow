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
        # TODO: use config.assets.local_public_path
        path = File.join("./public", env["PATH_INFO"])
        if path =~ /\.(.*)$/ && File.file?(path)
          catch :halt do
            headers = {
              "Content-Type" => Rack::Mime.mime_type(File.extname(path))
            }

            # TODO: do we want to do this?
            # if Pakyow::Config.assets.cache && Pakyow::Assets.fingerprinted?(File.extname(path))
            #   mtime = File.mtime(path)
            #   headers['Age'] = (Time.now - mtime).to_i
            #   headers['Cache-Control'] = 'public, max-age=31536000'
            #   headers['Vary'] = 'Accept-Encoding'
            #   headers['Last-Modified'] = mtime.httpdate
            # end

            [200, headers, File.open(path)]
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
