# frozen_string_literal: true

require "fileutils"

module Pakyow
  module Assets
    class Precompiler
      def initialize(app)
        @app = app
      end

      def precompile!
        @app.state_for(:asset).each do |asset|
          precompile_asset!(asset)
        end

        @app.state_for(:pack).each do |pack|
          if pack.javascripts?
            precompile_asset!(pack.javascripts)
          end

          if pack.stylesheets?
            precompile_asset!(pack.stylesheets)
          end
        end
      end

      def precompile_asset!(asset)
        compilation_path = File.join(@app.config.assets.compilation_path, asset.public_path)
        FileUtils.mkdir_p(File.dirname(compilation_path))

        asset_content = String.new
        asset.each do |content|
          asset_content << content
        end

        @app.state_for(:asset).each do |asset_state|
          asset_content.gsub!(asset_state.logical_path, asset_state.public_path)
        end

        File.open(compilation_path, "w+") do |file|
          file.write(asset_content)
        end
      end
    end
  end
end
