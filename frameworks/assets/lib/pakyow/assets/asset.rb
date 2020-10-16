# frozen_string_literal: true

require "digest/md5"

require "pakyow/support/class_state"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/assets/source_map"

module Pakyow
  module Assets
    # Represents an asset.
    #
    # Instances are created when booting in all environments, meaning the app
    # is guaranteed access to these objects. Contents are loaded and processed
    # eagerly. This is expected to happen under two scenarios:
    #
    #   1. In development, an asset is loaded and processed when it's requested.
    #   2. In production, when assets are precompiled during a deployment.
    #
    class Asset
      using Support::Refinements::String::Normalization

      extend Support::ClassState
      class_state :__types, default: []
      class_state :__emits, default: nil
      class_state :__extensions, default: [], inheritable: true
      class_state :__minifiable, default: false, inheritable: true

      class << self
        def new_from_path(path, config:, source_location: "", prefix: "/", related: [])
          asset_class = @__types.find { |type|
            type.__extensions.include?(File.extname(path))
          } || self

          asset_class.load
          asset_class.new(
            local_path: path,
            source_location: source_location,
            config: config,
            prefix: prefix,
            related: related
          )
        end

        # Implemented by subclasses to load any libraries they need.
        #
        def load
          # intentionally empty
        end

        # @api private
        def inherited(asset_class)
          @__types << asset_class
          super
        end

        # @api private
        def update_path_for_emitted_type(path)
          if @__emits
            path.sub(File.extname(path), @__emits)
          else
            path
          end
        end

        private

        # Registers +extension+ for this asset.
        #
        def extension(extension)
          extensions(extension)
        end

        # Registers multiple extensions for this asset.
        #
        def extensions(*extensions)
          extensions.each do |extension|
            @__extensions << ".#{extension}"
          end
        end

        # Defines the emitted asset type (e.g. +sass+ emits +css+).
        #
        def emits(type)
          @__emits = ".#{type}"
        end
      end

      attr_reader :logical_path, :mime_type, :mime_suffix, :dependencies

      def initialize(local_path:, config:, dependencies: [], source_location: "", prefix: "/", related: [])
        @local_path, @config, @source_location, @dependencies, @related = local_path, config, source_location, dependencies, related

        @logical_path = self.class.update_path_for_emitted_type(
          String.normalize_path(
            File.join(prefix, local_path.sub(source_location, ""))
          )
        )

        @public_path = String.normalize_path(
          File.join(config.prefix, @logical_path)
        )

        @mime_type = case File.extname(@public_path)
        when ".js"
          # Resolves an issue with mini_mime returning `application/ecmascript`
          #
          "application/javascript"
        else
          MiniMime.lookup_by_filename(@public_path)&.content_type.to_s
        end

        @mime_prefix, @mime_suffix = @mime_type.split("/", 2)

        @source_map_enabled = config.source_maps

        @mutex = Mutex.new
      end

      # Overriding and freezing after content is set lets us eagerly process the
      # content rather than incurring that cost on boot.
      #
      def freeze
        @freezing = true
        unless @freezing
          public_path
        end

        if instance_variable_defined?(:@content) && (!@config.fingerprint || instance_variable_defined?(:@fingerprinted_public_path))
          super
        end
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        ensure_content do |content|
          StringIO.new(post_process(content)).each(&block)
        end
      end

      def read
        asset = +""

        each do |content|
          asset << content
        end

        asset
      end

      def bytesize
        ensure_content(&:bytesize)
      end

      def fingerprint
        [@local_path].concat(dependencies).each_with_object(Digest::MD5.new) { |path, digest|
          digest.update(Digest::MD5.file(path).hexdigest)
        }.hexdigest
      end

      def fingerprinted_filename
        extension = File.extname(@public_path)
        File.basename(@public_path, extension) + "__" + fingerprint + extension
      end

      def public_path
        if @config.fingerprint
          unless instance_variable_defined?(:@fingerprinted_public_path)
            @fingerprinted_public_path = File.join(
              File.dirname(@public_path),
              fingerprinted_filename
            )

            freeze
          end

          @fingerprinted_public_path
        else
          @public_path
        end
      end

      def source_map?
        respond_to?(:source_map_content)
      end

      def source_map
        if source_map?
          SourceMap.new(
            source_map_content,
            file: File.basename(public_path)
          )
        end
      end

      def disable_source_map
        @source_map_enabled = false
        self
      end

      private

      def ensure_content
        @mutex.synchronize do
          unless frozen? || instance_variable_defined?(:@content)
            @content = load_content
            freeze
          end
        end

        yield @content if block_given?
      end

      def load_content
        content = process(File.read(@local_path)).to_s

        if mime_suffix == "css" || mime_suffix == "javascript"
          # Update references to related assets with prefixed path, fingerprints.
          # Do this here rather than in post-processing so that the source maps reflect the changes.
          #
          @related.each do |asset|
            if asset != self && content.include?(asset.logical_path)
              content.gsub!(asset.logical_path, File.join(@config.host, asset.public_path))
            end
          end
        end

        content
      end

      def process(content)
        content
      end

      def post_process(content)
        if @source_map_enabled && source_map?
          embed_mapping_url(content)
        else
          content
        end
      end

      def embed_mapping_url(content)
        content + SourceMap.mapping_url(path: public_path, type: @mime_suffix)
      end

      def external?
        File.dirname(@local_path) == @config.externals.path
      end
    end
  end
end
