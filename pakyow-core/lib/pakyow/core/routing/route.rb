require "pakyow/core/routing/hook_merger"

module Pakyow
  module Routing
    # A route, consisting of a name, path, and pipeline. The pipeline is a list
    # of procs and/or method names that are called in order when the route is
    # matched and executed. Pipelines are constructed at runtime.
    #
    # @api private
    class Route
      include HookMerger

      attr_reader :method, :name, :path, :parameterized_path, :block, :hooks, :pipeline, :formats

      def initialize(method: nil, name: nil, path: nil, hooks: nil, &block)
        @method   = method
        @name     = name
        @path     = configure_path(path)
        @block    = block
        @hooks    = hooks
        @formats  = []
        @pipeline = compile_pipeline
        @parameterized_path = nil

        find_path_formats
        parameterize_path
      end

      def match?(path_to_match, params, format)
        case path
        when Regexp
          if data = path.match(path_to_match)
            params.merge!(Hash[data.names.zip(data.captures)])
            true
          end
        when String
          formats.include?(format) && path == path_to_match
        else
          false
        end
      end

      def call(context)
        @pipeline.each do |route|
          if route.is_a?(Proc)
            context.instance_exec(&route)
          else
            context.__send__(route)
          end
        end
      end

      def populated_path(**params)
        return path unless parameterized?
        parameterized_path.split("/").map { |path_segment|
          if path_segment[0] == ":"
            params[path_segment[1..-1].to_sym]
          else
            path_segment
          end
        }.join("/")
      end

      def freeze
        hooks.each do |_, hooks_arr|
          hooks_arr.each(&:freeze)
          hooks_arr.freeze
        end

        path.freeze
        pipeline.freeze
        formats.freeze
        hooks.freeze

        super
      end

      protected

      def compile_pipeline
        [
          hooks[:around],
          hooks[:before],
          block,
          hooks[:after],
          hooks[:around]
        ].flatten.compact
      end

      def configure_path(path)
        return path unless path.is_a?(String)
        String.normalize_path(path)
      end

      def parameterize_path
        return unless @path.is_a?(String) && @path.include?(":")

        # replace named parameters with a named capture
        regex_path = @path.split("/").map { |segment|
          if segment.include?(":")
            "(?<#{segment[1..-1]}>(\\w|[-.~:@!$\\'\\(\\)\\*\\+,;])*)"
          else
            segment
          end
        }.join("/")

        @parameterized_path = @path

        # perform the actual matching via regex
        @path = Regexp.new(regex_path)
      end

      def find_path_formats
        return unless @path.is_a?(String)

        if @path.include?(".")
          path, formats = @path.split(".")
          @formats.concat(formats.split("|").map(&:to_sym))
          @path = path
        else
          @formats << :html
        end
      end

      def parameterized?
        !@parameterized_path.nil?
      end
    end
  end
end
