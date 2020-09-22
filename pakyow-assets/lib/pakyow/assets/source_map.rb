# frozen_string_literal: true

require "json"
require "forwardable"
require "pathname"

require "source_map"

module Pakyow
  module Assets
    class SourceMap
      class << self
        def mapping_url(path:, type:)
          case type.to_sym
          when :css
            "\n/*# sourceMappingURL=#{path}.map */\n"
          when :javascript
            "\n//# sourceMappingURL=#{path}.map\n"
          end
        end
      end

      extend Forwardable
      def_delegators :@internal, :mappings

      attr_reader :file, :sources, :sources_content

      def initialize(content = nil, file:)
        @file = file

        @raw = content

        if content.is_a?(String)
          content = JSON.parse(content)
        end

        @sources = if content
          content["sources"].dup
        else
          []
        end

        @sources_content = if content
          content["sourcesContent"].to_a
        else
          []
        end

        @internal = if content.nil?
          ::SourceMap.new
        else
          ::SourceMap.from_json(content)
        end
      end

      def merge(other)
        other.mappings.each do |mapping|
          @internal.add_mapping(mapping)
        end

        @sources.concat(other.sources)
        @sources_content.concat(other.sources_content)

        self
      end

      def mime_type
        "application/octet-stream"
      end

      def bytesize
        read.bytesize
      end

      def read
        root = "/"
        map = @internal.as_json
        map["file"] = @file
        map["sourceRoot"] = root

        # The source_map gem reorders sources, so make sure that the sources content matches.
        #
        map["sourcesContent"] = map["sources"].map { |source|
          @sources_content[@sources.index(source)]
        }

        map["sources"].map! do |source|
          File.join(root, source)
        end

        map.to_json
      end

      def each(&block)
        StringIO.new(read).each(&block)
      end
    end
  end
end
