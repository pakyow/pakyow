# frozen_string_literal: true

module Pakyow
  class Application
    module Actions
      module Assets
        # Pipeline Action that processes assets at request time.
        #
        # This is intended for development use, please don't use it in production.
        # Instead, precompile assets into the public directory.
        #
        class Process
          def call(connection)
            if connection.app.config.assets.process
              # TODO: can we short circuit if the request path doesn't match the connection?
              if (asset = find_asset(connection) || find_pack(connection) || find_asset_map(connection) || find_pack_map(connection))
                connection.set_header("content-type", asset.mime_type)
                connection.body = asset
                connection.halt
              end
            end
          end

          private

          def find_asset(connection, path = connection.path)
            connection.app.assets.each.find { |asset|
              asset.public_path == path
            }
          end

          def find_pack(connection, path = connection.path)
            connection.app.packs.each.lazy.map { |pack|
              pack.packed(path)
            }.find { |packed| !packed.nil? && packed.any? }
          end

          def find_asset_map(connection)
            if wants_map?(connection)
              if (asset = find_asset(connection, unmapped(connection))) && asset.source_map?
                asset.source_map
              end
            end
          end

          def find_pack_map(connection)
            if (pack = find_pack(connection, unmapped(connection))) && pack.source_map?
              pack.source_map
            end
          end

          def wants_map?(connection)
            connection.path.end_with?(".map")
          end

          def unmapped(connection)
            File.join(File.dirname(connection.path), File.basename(connection.path, ".map"))
          end
        end
      end
    end
  end
end
