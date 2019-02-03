# frozen_string_literal: true

require "fileutils"

module Pakyow
  module Assets
    class Precompiler
      def initialize(app)
        @app = app
      end

      def precompile!
        assets.each do |asset|
          precompile_asset!(asset)
        end

        packs.each do |pack|
          if pack.javascripts?
            precompile_asset!(pack.javascripts)
          end

          if pack.stylesheets?
            precompile_asset!(pack.stylesheets)
          end
        end
      end

      def precompile_asset!(asset)
        compile_path = File.join(@app.config.assets.compile_path, asset.public_path)
        FileUtils.mkdir_p(File.dirname(compile_path))

        asset_content = String.new
        asset.each do |content|
          asset_content << content
        end

        File.open(compile_path, "w+") do |file|
          file.write(asset_content)
        end

        if @app.config.assets.source_maps && source_map = asset.source_map
          File.open(compile_path + ".map", "w+") do |file|
            file.write(source_map.read)
          end
        end
      end

      private

      def assets
        @app.state(:asset) + @app.plugs.flat_map { |plug|
          plug.state(:asset)
        }
      end

      def packs
        @app.state(:pack) + @app.plugs.flat_map { |plug|
          plug.state(:pack)
        }
      end
    end
  end
end
