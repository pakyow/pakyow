module Pakyow
  module Routing
    class Route
      attr_reader :name, :path, :parameterized_path, :block, :hooks, :pipeline

      def initialize(name: nil, path: nil, hooks: nil, &block)
        @name     = name
        @path     = path
        @block    = block
        @hooks    = hooks
        @pipeline = compile_pipeline(block, hooks)

        if @path.is_a?(String)
          @path = String.normalize_path(path)
          parameterize_path
        end
      end

      def match?(path_to_match, params)
        case path
        when Regexp
          if data = path.match(path_to_match)
            params.merge!(Hash[data.names.zip(data.captures)])
            true
          end
        when String
          path == path_to_match
        else
          false
        end
      end

      def call(context: nil)
        if context.nil?
          @pipeline.each(&:call)
        else
          @pipeline.each do |route|
            if context
              context.instance_exec(&route)
            else
              route.call
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
        @hooks = merge_hooks(@hooks, hooks) if hooks
        @pipeline = compile_pipeline(@block, @hooks)
      end

      def parameterized?
        !@parameterized_path.nil?
      end

      def freeze
        path.freeze
        pipeline.freeze
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

      # TODO: move into Routing::Helpers
      def merge_hooks(hooks, hooks_to_merge)
        hooks.each_pair do |type, hooks_of_type|
          hooks_of_type.concat(hooks_to_merge[type] || [])
        end
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
    end
  end
end
