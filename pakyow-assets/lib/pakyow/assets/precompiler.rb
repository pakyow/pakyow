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

        if @app.config.assets.source_maps
          source_map = asset.source_map
        end

        if asset.mime_suffix == "css" || asset.mime_suffix == "javascript"
          # Update asset references with prefix, fingerprints.
          #
          asset_content = asset_content.split("\n").map.with_index { |line, line_index|
            line_number = line_index + 1

            @app.state(:asset).each do |asset_state|
              diff = asset_state.public_path.length - asset_state.logical_path.length

              line.to_enum(:scan, asset_state.logical_path).map {
                Regexp.last_match
              }.each_with_index do |match, match_i|
                # Update source mappings to reflect the change in content.
                #
                if source_map
                  col_s, col_e = match.offset(0)

                  incr = match_i * diff
                  col_s += incr
                  col_e += incr

                  source_map.mappings.select { |mapping|
                    mapping[:generated_line] == line_number
                  }.select { |mapping|
                    mapping[:generated_col] > col_e
                  }.each do |mapping|
                    mapping[:generated_col] += diff
                  end
                end

                # Replace the string with the new path.
                #
                line[col_s...col_e] = asset_state.public_path
              end
            end

            line
          }.join("\n")
        end

        File.open(compile_path, "w+") do |file|
          file.write(asset_content)
        end

        if source_map
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
