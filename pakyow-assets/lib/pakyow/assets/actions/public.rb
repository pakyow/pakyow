# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Assets
    module Actions
      class Public
        using Support::Refinements::String::Normalization

        # Pipeline Action that serves files out of your public directory.
        #
        def initialize(app)
          @asset_paths = app.state(:asset).map(&:public_path) + app.state(:pack).flat_map { |pack|
            [pack.public_css_path, pack.public_js_path]
          }

          @prefix = if app.is_a?(Plugin)
            Pathname.new(app.class.mount_path)
          else
            Pathname.new("/")
          end
        end

        def call(connection)
          if connection.app.config.assets.public
            public_path = public_path(connection)

            if public?(public_path)
              file = File.open(public_path)
              connection.set_header(Rack::CONTENT_TYPE, Rack::Mime.mime_type(File.extname(public_path)))

              if connection.app.config.assets.cache && asset?(connection)
                set_cache_headers(connection, public_path)
              end

              connection.body = file
              connection.halt
            end
          end
        end

        private

        def public?(path)
          File.file?(path)
        end

        def public_path(connection)
          File.join(
            connection.app.config.assets.public_path,
            String.normalize_path(
              Pathname.new(connection.path).relative_path_from(@prefix).to_s
            )
          )
        end

        def asset?(connection)
          @asset_paths.include?(connection.path)
        end

        def set_cache_headers(connection, public_path)
          mtime = File.mtime(public_path)
          connection.set_header("age", (Time.now - mtime).to_i.to_s)
          connection.set_header("cache-control", "public, max-age=31536000")
          connection.set_header("vary", "accept-encoding")
          connection.set_header("last-modified", mtime.httpdate)
        end
      end
    end
  end
end
