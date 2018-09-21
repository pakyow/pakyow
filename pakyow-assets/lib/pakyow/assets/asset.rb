# frozen_string_literal: true

require "digest/md5"

require "pakyow/support/class_state"
require "pakyow/support/core_refinements/string/normalization"

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
        def new_from_path(path, config:, source_location: "", prefix: "/")
          asset_class = @__types.find { |type|
            type.__extensions.include?(File.extname(path))
          } || self

          asset_class.load; asset_class.new(
            local_path: path,
            source_location: source_location,
            config: config,
            prefix: prefix
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

      attr_reader :logical_path, :public_path, :mime_type, :mime_suffix, :dependencies

      def initialize(local_path:, config:, dependencies: [], source_location: "", prefix: "/")
        @local_path, @config, @source_location, @dependencies = local_path, config, source_location, dependencies

        @logical_path = self.class.update_path_for_emitted_type(
          String.normalize_path(
            File.join(prefix, local_path.sub(source_location, ""))
          )
        )

        @public_path = String.normalize_path(
          File.join(config.prefix, @logical_path)
        )

        if config.fingerprint
          @public_path = File.join(
            File.dirname(@public_path),
            fingerprinted_filename
          )
        end

        @mime_type = Rack::Mime.mime_type(File.extname(@public_path))
        @mime_prefix, @mime_suffix = @mime_type.split("/", 2)

        if config.minify
          require "uglifier"

          @minifier = case @mime_suffix
          when "javascript"
            Uglifier.new
          else
            nil
          end
        else
          @minifier = nil
        end
      end

      def each(&block)
        ensure_content do |content|
          content = process(content)

          if minify?
            content = minify(content)
          end

          StringIO.new(content).each(&block)
        end
      end

      def read
        String.new.tap do |asset|
          each do |content|
            asset << content
          end
        end
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

      private

      def minify?
        !@minifier.nil?
      end

      def ensure_content
        yield File.read(@local_path) if block_given?
      end

      def process(content)
        content
      end

      def minify(content)
        begin
          @minifier.compress(content)
        rescue StandardError
          Pakyow.logger.warn "Unable to minify #{@local_path}; using raw content instead"
          content
        end
      end

      def external?
        File.dirname(@local_path) == @config.externals.path
      end
    end
  end
end
