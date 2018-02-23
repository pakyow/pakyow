# frozen_string_literal: true

require "digest/md5"

require "pakyow/support/class_state"
require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Assets
    # Represents an asset, which may be made up of more than one file.
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
        def new_from_path(path, source_location:, minify: false)
          type = @types.find { |type|
            type._extensions.include?(File.extname(path))
          } || self

          type.load; type.new(
            local_path: path,
            source_location: source_location,
            minify: minify
          )
        end

        def inherited(asset_class)
          @types << asset_class
          super
        end

        def _extensions
          @extensions
        end

        def _emits
          @emits
        end

        def processable?
          @processable == true
        end

        def processable
          @processable = true
        end

        def load
          # intentionally empty
        end

        def update_path_for_emitted_type(path)
          if @emits
            path.sub(File.extname(path), @emits)
          else
            path
          end
        end

        private

        def extension(extension)
          extensions(extension)
        end

        def extensions(*extensions)
          extensions.each do |extension|
            @extensions << ".#{extension}"
          end
        end

        def emits(type)
          @emits = ".#{type}"
        end
      end

      attr_reader :public_path, :mime_type, :dependencies

      def initialize(local_path:, source_location:, dependencies: [], minify: false)
        @local_path, @source_location, @dependencies = local_path, source_location, dependencies

        @public_path = self.class.update_path_for_emitted_type(
          String.normalize_path(
            local_path.sub(source_location, "")
          )
        )

        @mime_type = Rack::Mime.mime_type(File.extname(@public_path))
        @mime_prefix, @mime_suffix = @mime_type.split("/", 2)

        if minify
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
    end
  end
end
