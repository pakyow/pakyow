# frozen_string_literal: true

module Pakyow
  class Loader
    # @api private
    class Context
      def initialize(target, code, path)
        @target, @path = target, path

        @comments, @uncommented_code = split_comments(code)
      end

      def load
        eval(@uncommented_code, binding, @path, @comments.lines.count + 1)
      end

      def method_missing(name, *args, **kwargs, &block)
        inner_source = if block
          inner_source(block.source)
        else
          "\n"
        end

        local_comments = @comments
        local_path = @path

        @target.public_send(name, *args, **kwargs) do
          if self.name
            code_to_eval = case self
            when Class
              <<~CODE
                #{local_comments}class #{self}#{inner_source}end
              CODE
            when Module
              <<~CODE
                #{local_comments}module #{self}#{inner_source}end
              CODE
            end

            eval(code_to_eval, binding, local_path, 1)
          else
            class_eval(&block)
          end
        end
      end

      def respond_to_missing?(name, include_private = false)
        @target.respond_to?(name, include_private) || super
      end

      private def indent(code)
        code.split("\n").map { |line| "  #{line}" }.join("\n")
      end

      private def split_comments(code)
        lines = code.lines

        line_number = first_nonblank_or_commented_line_number(lines)

        if lines.empty? || line_number == 1
          return "", code
        else
          return lines[0...(line_number - 1)].join, lines[(line_number - 1)..-1].join
        end
      end

      private def first_nonblank_or_commented_line_number(lines)
        lines.each_with_index do |line, index|
          clean_line = line.strip

          unless clean_line.empty? || clean_line[0] == "#"
            return index + 1
          end
        end

        nil
      end

      TRAILING_WHITESPACE = /(\s+)$/

      private def inner_source(source)
        trailing_whitespace = if (match = source.match(TRAILING_WHITESPACE))
          match[1]
        else
          ""
        end

        source = source.rstrip

        inner_source = if source.end_with?("end")
          scan_to_complete_expression(source, "do", -4)
        elsif source.end_with?("}")
          scan_to_complete_expression(source, "{", -2)
        else
          # We should never get here, but raise an error just to be clear.
          #
          raise RuntimeError, "could not parse inner source of `#{@path}'"
        end

        inner_source + trailing_whitespace
      end

      private def scan_to_complete_expression(source, matcher, ending_offset)
        source.scan(matcher) do
          offset = $~.offset(0)[0] + 2

          possible_inner_source = source[offset..ending_offset]

          if MethodSource.complete_expression?(possible_inner_source)
            return possible_inner_source
          end
        rescue SyntaxError
          # It's fine to eat these since we're just trying to find a valid expression.
        end

        # We should never get here, but raise an error just to be clear.
        #
        raise RuntimeError, "could not find a complete expression for `#{matcher}' in `#{@path}'"
      end
    end
  end
end
