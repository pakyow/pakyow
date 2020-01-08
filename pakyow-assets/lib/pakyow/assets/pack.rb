# frozen_string_literal: true

require "digest/md5"
require "forwardable"

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/assets/asset"
require "pakyow/assets/source_map"

module Pakyow
  module Assets
    class Pack
      using Support::Refinements::String::Normalization

      attr_reader :name, :public_path

      def initialize(name, config, prefix: "/")
        @name, @config = name, config
        @assets = []
        @packed = { js: [], css: [] }
        @public_path = String.normalize_path(
          File.join(config.prefix, prefix, "packs", name.to_s)
        )
      end

      def finalize
        tap do
          if @config.fingerprint
            extension = File.extname(@public_path)
            @public_path = File.join(
              File.dirname(@public_path),
              File.basename(@public_path, extension) + "__" + fingerprint + extension
            )
          end

          pack_assets!
        end
      end

      def <<(asset)
        @assets << asset.disable_source_map
      end

      def packed(path)
        if path.start_with?(@public_path + ".")
          @packed[File.extname(path)[1..-1].to_sym]
        else
          nil
        end
      end

      def javascripts
        @packed[:js]
      end

      def stylesheets
        @packed[:css]
      end

      def javascripts?
        javascripts.any?
      end

      def stylesheets?
        stylesheets.any?
      end

      def fingerprint
        @assets.flat_map(&:fingerprint).sort.each_with_object(Digest::MD5.new) { |fingerprint, digest|
          digest.update(fingerprint)
        }.hexdigest
      end

      def public_js_path
        @public_path + ".js"
      end

      def public_css_path
        @public_path + ".css"
      end

      def object_name
        self.class.object_name
      end

      private

      def pack_assets!
        @packed[:js] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "javascript"
        }, public_js_path, @config, @name)

        @packed[:css] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "css"
        }, public_css_path, @config, @name)
      end
    end

    class PackedAssets
      extend Forwardable
      def_delegators :@assets, :any?

      attr_reader :public_path, :assets

      def initialize(assets, public_path, config, name)
        @assets, @public_path, @config, @name = assets, public_path, config, name
      end

      def initialize_copy(_)
        super

        @assets = @assets.map(&:dup)
      end

      def mime_type
        @assets.first&.mime_type
      end

      def mime_suffix
        @assets.first&.mime_suffix
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        @assets.each do |asset|
          asset.each(&block)
        end

        if @config.source_maps && source_map?
          yield source_mapping_url
        end
      end

      def read
        String.new.tap do |packed_asset|
          @assets.each do |asset|
            packed_asset << asset.read
          end

          if @config.source_maps && source_map?
            packed_asset << source_mapping_url
          end
        end
      end

      def bytesize
        bytes = @assets.map(&:bytesize).inject(&:+)

        if @config.source_maps && source_map?
          bytes += source_mapping_url.bytesize
        end

        bytes
      end

      def source_map
        @assets.select(&:source_map?).inject(
          SourceMap.new(
            file: File.basename(@public_path)
          )
        ) { |merged, asset|
          merged.merge(asset.source_map)
        }
      end

      def source_map?
        @assets.any?(&:source_map?)
      end

      def source_mapping_url
        SourceMap.mapping_url(path: @public_path, type: @assets.first.mime_suffix)
      end
    end
  end
end
