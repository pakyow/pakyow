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
      class_state :types, default: []
      class_state :extensions, default: [], inheritable: true
      class_state :processable, default: false, inheritable: true
      class_state :minifiable, default: false, inheritable: true

      class << self
        def new_from_path(path, config:, source_location: "")
          type = @types.find { |type|
            type._extensions.include?(File.extname(path))
          } || self

          type.load; type.new(
            local_path: path,
            source_location: source_location,
            config: config
          )
        end

        # Implemented by subclasses to load any libraries they need.
        #
        def load
          # intentionally empty
        end

        # @api private
        def inherited(asset_class)
          @types << asset_class
          super
        end

        # @api private
        def _extensions
          @extensions
        end

        # @api private
        def _emits
          @emits
        end

        # @api private
        def processable?
          @processable == true
        end

        # @api private
        def update_path_for_emitted_type(path)
          if @emits
            path.sub(File.extname(path), @emits)
          else
            path
          end
        end

        private

        # Marks the asset as being processable.
        #
        def processable
          @processable = true
        end

        # Registers +extension+ for this asset.
        #
        def extension(extension)
          extensions(extension)
        end

        # Registers multiple extensions for this asset.
        #
        def extensions(*extensions)
          extensions.each do |extension|
            @extensions << ".#{extension}"
          end
        end

        # Defines the emitted asset type (e.g. +sass+ emits +css+).
        #
        def emits(type)
          @emits = ".#{type}"
        end
      end

      attr_reader :logical_path, :public_path, :mime_type, :mime_suffix, :dependencies

      def initialize(local_path:, config:, dependencies: [], source_location: "")
        @local_path, @config, @source_location, @dependencies = local_path, config, source_location, dependencies

        @logical_path = self.class.update_path_for_emitted_type(
          String.normalize_path(
            local_path.sub(source_location, "")
          )
        )

        @public_path = String.normalize_path(
          File.join(config.prefix, @logical_path)
        )

        @mime_type = Rack::Mime.mime_type(File.extname(@public_path))
        @mime_prefix, @mime_suffix = @mime_type.split("/", 2)

        if config.minify
          require "yui/compressor"

          @minifier = case @mime_suffix
          when "css"
            YUI::CssCompressor.new
          when "javascript"
            YUI::JavaScriptCompressor.new
          else
            nil
          end
        end
      end

      def each(&block)
        if self.class.processable? || minify?
          ensure_content do |content|
            content = process(content) if self.class.processable?
            content = minify(content) if minify?
            StringIO.new(content).each(&block)
          end
        else
          File.open(@local_path, "r") do |file|
            file.each_line(&block)
          end
        end
      end

      def fingerprint
        [@local_path].concat(dependencies).each_with_object(Digest::MD5.new) { |path, digest|
          digest.update(Digest::MD5.file(path).hexdigest)
        }.hexdigest
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
        rescue YUI::Compressor::RuntimeError
          Pakyow.logger.warn "Unable to minify #{@local_path}; using raw content instead"
          content
        end
      end
    end
  end
end
