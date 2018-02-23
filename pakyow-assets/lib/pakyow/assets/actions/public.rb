# frozen_string_literal: true

module Pakyow
  module Assets
    module Actions
      class Public
        # Pipeline Action that serves files out of your public directory.
        #
        def initialize(_)
        end

        def call(connection)
          if connection.app.config.assets.public
            public_path = public_path(connection)

            if public?(public_path)
              connection.set_response_header("Content-Type", Rack::Mime.mime_type(File.extname(public_path)))

              if connection.app.config.assets.cache && asset?(connection)
                set_cache_headers(connection, public_path)
              end

              connection.body = File.open(public_path)
              connection.halt
            end
          end
        end

        private

        def public?(path)
          File.file?(path)
        end

        def public_path(connection)
          File.join(connection.app.config.assets.public_path, connection.path)
        end

        def asset?(connection)
          connection.app.state_for(:asset).any? { |asset|
            asset.public_path == connection.path
          }
        end

        def set_cache_headers(connection, public_path)
          mtime = File.mtime(public_path)
          connection.set_response_header("Age", (Time.now - mtime).to_i)
          connection.set_response_header("Cache-Control", "public, max-age=31536000")
          connection.set_response_header("Vary", "Accept-Encoding")
          connection.set_response_header("Last-Modified", mtime.httpdate)
        end
      end
    end
  end
end
