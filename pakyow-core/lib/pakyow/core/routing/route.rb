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
      attr_accessor :callable_method

      def initialize(name: nil, path: nil, hooks: nil, &block)
        @name     = name
        @path     = path
        @block    = block
        @hooks    = hooks
        @formats  = []
        @pipeline = compile_pipeline(block, hooks)
        @parameterized_path = nil

        if @path.is_a?(String)
          @path = String.normalize_path(path)

          find_path_formats
          parameterize_path
        end
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

      def call(context: nil)
        if context.nil?
          @pipeline.each(&:call)
        else
          @pipeline.each do |route|
            if route.is_a?(Proc)
              context.instance_exec(&route)
            else
              context.__send__(route)
            end
          end
        end
      end

      def populated_path(**params)
        parameterized_path.split("/").map { |path_segment|
          if path_segment[0] == ":"
            params[path_segment[1..-1].to_sym]
          else
            path_segment
          end
        }.join("/")
      end

      def recompile(block: nil, hooks: nil)
        @block = block if block
        @pipeline = compile_pipeline(@block, @hooks)
          @hooks = merge_hooks(hooks)
      end

      def parameterized?
        !@parameterized_path.nil?
      end

      def freeze
        path.freeze
        pipeline.freeze
        formats.freeze
        # TODO: freeze hooks
        super
      end

      protected

      # TODO: move into Routing::Helpers
      def compile_pipeline(block, hooks)
        [
          hooks[:around],
          hooks[:before],
          block,
          hooks[:after],
          hooks[:around]
        ].flatten.compact
      end

      def parameterize_path
        if @path.include?(":")
          # replace named parameters with a named capture
          reqex_path = @path.split("/").map { |segment|
            if segment.include?(":")
              '(?<' + segment[1..-1] + '>(\w|[-.~:@!$\'\(\)\*\+,;])*)'
            else
              segment
            end
          }.join("/")

          @parameterized_path = @path

          # perform the actual matching via regex
          @path = Regexp.new("^#{reqex_path}$")
        end
      end
      
      def find_path_formats
        if @path.include?(".")
          path, formats = @path.split(".")
          @formats.concat(formats.split("|").map(&:to_sym))
          @path = path
        else
          @formats << :html
        end
      end
    end
  end
end
