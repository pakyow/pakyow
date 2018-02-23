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

      def initialize(name)
        @name = name
        @public_path = String.normalize_path(name)
        @assets = []
        @packed = { js: [], css: [] }
      end

      def freeze
        pack_assets!
        super
      end

      def <<(asset)
        @assets << asset
      end

      def packed(path)
        if path.start_with?(@public_path)
          @packed[File.extname(path)[1..-1].to_sym]
        else
          nil
        end
      end

      def javascripts?
        @packed[:js].any?
      end

      def stylesheets?
        @packed[:css].any?
      end

      def fingerprint
        @assets.flat_map(&:fingerprint).each_with_object(Digest::MD5.new) { |fingerprint, digest|
          digest.update(fingerprint)
        }.hexdigest
      end

      private

      def pack_assets!
        @packed[:js] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "javascript"
        })

        @packed[:css] = PackedAssets.new(@assets.select { |asset|
          asset.mime_suffix == "css"
        })
      end
    end

    class PackedAssets
      extend Forwardable
      def_delegators :@assets, :any?

      def initialize(assets)
        @assets = assets
      end

      def mime_type
        @assets.first&.mime_type
      end

      def each(&block)
        @assets.each do |asset|
          asset.each(&block)
        end
      end
    end
  end
end
