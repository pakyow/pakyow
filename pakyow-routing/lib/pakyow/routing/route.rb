# frozen_string_literal: true

require "pakyow/support/aargv"
require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Routing
    # A {Controller} endpoint.
    #
    class Route
      using Support::Refinements::String::Normalization

      attr_reader :path, :method, :name, :pipeline

      def initialize(path_or_matcher, name:, method:, &block)
        @name, @method, @block = name, method, block

        if path_or_matcher.is_a?(String)
          @path    = path_or_matcher
          @matcher = create_matcher_from_path(@path)
        else
          @path    = ""
          @matcher = path_or_matcher
        end
      end

      def match(path_to_match)
        @matcher.match(path_to_match)
      end

      def call(context)
        context.instance_exec(&@block) if @block
      end

      def populated_path(path_to_self, **params)
        String.normalize_path(File.join(path_to_self.to_s, @path.to_s).split("/").map { |path_segment|
          if path_segment.include?(":")
            path_segment.sub(path_segment[(path_segment.index(":"))..-1], params[path_segment[(path_segment.index(":") + 1)..-1].to_sym].to_s)
          else
            path_segment
          end
        }.join("/")).gsub("/#", "#")
      end

      protected

      def create_matcher_from_path(path)
        converted_path = String.normalize_path(path.split("/").map { |segment|
          if segment.include?(":")
            "(?<#{segment[(segment.index(":") + 1)..-1]}>(\\w|[-~:@!$\\'\\(\\)\\*\\+,;])*)"
          else
            segment
          end
        }.join("/"))

        Regexp.new("^#{converted_path}$")
      end
    end
  end
end
