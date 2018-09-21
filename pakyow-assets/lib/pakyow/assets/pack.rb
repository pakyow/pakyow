# frozen_string_literal: true

require "digest/md5"
require "forwardable"

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/assets/asset"

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
        @assets << asset
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

      private

      def pack_assets!
        @packed[:js] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "javascript"
        }, public_js_path)

        @packed[:css] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "css"
        }, public_css_path)
      end
    end

    class PackedAssets
      extend Forwardable
      def_delegators :@assets, :any?

      attr_reader :public_path

      def initialize(assets, public_path)
        @assets, @public_path = assets, public_path
      end

      def mime_type
        @assets.first&.mime_type
      end

      def each(&block)
        @assets.each do |asset|
          asset.each(&block)
        end
      end

      def read
        String.new.tap do |packed_asset|
          @assets.each do |asset|
            packed_asset << asset.read
          end
        end
      end
    end
  end
end
