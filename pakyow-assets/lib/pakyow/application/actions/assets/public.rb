# frozen_string_literal: true

require "mini_mime"

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  class Application
    module Actions
      module Assets
        class Public
          using Support::Refinements::String::Normalization

          # Pipeline Action that serves files out of your public directory.
          #
          def initialize(app)
            @asset_paths = app.assets.each.map(&:public_path) + app.packs.each.flat_map { |pack|
              [pack.public_css_path, pack.public_js_path]
            }
          end

          def call(connection)
            if connection.app.config.assets.public
              public_path = public_path(connection)

              if public?(public_path)
                if mime = MiniMime.lookup_by_filename(public_path)
                  connection.set_header("content-type", mime.content_type)
                end

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
end
