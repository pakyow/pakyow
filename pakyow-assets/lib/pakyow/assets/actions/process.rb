# frozen_string_literal: true

module Pakyow
  module Assets
    module Actions
      # Pipeline Action that processes assets at request time.
      #
      # This is intended for development use, please don't use it in production.
      # Instead, precompile assets into the public directory.
      #
      class Process
        def call(connection)
          asset = find_asset(connection) || find_pack(connection)

          if connection.app.config.assets.process && asset
            asset = asset.dup
            connection.set_response_header(Rack::CONTENT_LENGTH, asset.bytesize)
            connection.set_response_header(Rack::CONTENT_TYPE, asset.mime_type)
            connection.body = asset.dup
            connection.halt
          end
        end

        private

        def find_asset(connection)
          connection.app.state(:asset).find { |asset|
            asset.logical_path == connection.path
          }
        end

        def find_pack(connection)
          connection.app.state(:pack).lazy.map { |pack|
            pack.packed(connection.path)
          }.find { |packed| !packed.nil? && packed.any? }
        end
      end
    end
  end
end
