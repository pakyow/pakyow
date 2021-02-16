# frozen_string_literal: true

class PakyowToplevel < BasicObject
  def self.const_missing(name)
    ::Object.const_get(name)
  end

  def self.load(code, path, lineno)
    eval(code, binding, path, lineno)
  end

  def self.method_missing(name, *args, **kwargs, &block)
    context = ::Thread.current[:__pw_loader_context]

    if context.target.ancestors.include?(::Pakyow::Support::Definable) && context.target.__definable_registries.key?(name)
      inner_source = if block
        inner_source(block.source)
      else
        "\n"
      end

      defined = context.target.public_send(name, *args, **kwargs) do
        # Intentionally blank.
      end

      if defined.name.nil?
        defined.class_eval(&block)
      else
        code_to_eval = case defined
        when ::Class
          "#{context.comments}class #{defined}#{inner_source}end"
        when ::Module
          "#{context.comments}module #{defined}#{inner_source}end"
        end

        eval(code_to_eval, TOPLEVEL_BINDING, context.path, 1)
      end
    else
      context.target.public_send(name, *args, **kwargs, &block)
    end
  end

  def self.respond_to_missing?(name, include_private = false)
    ::Thread.current[:__pw_loader_context].target.respond_to?(name, include_private) || super
  end

  TRAILING_WHITESPACE = /(\s+)$/

  def self.inner_source(source)
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
      raise "could not parse inner source of `#{@path}'"
    end

    inner_source + trailing_whitespace
  end

  def self.scan_to_complete_expression(source, matcher, ending_offset)
    source.scan(matcher) do
      offset = $~.offset(0)[0] + 2

      possible_inner_source = source[offset..ending_offset]

      if ::MethodSource.complete_expression?(possible_inner_source)
        return possible_inner_source
      end
    rescue ::SyntaxError
      # It's fine to eat these since we're just trying to find a valid expression.
    end

    # We should never get here, but raise an error just to be clear.
    #
    raise "could not find a complete expression for `#{matcher}' in `#{@path}'"
  end
end

module Pakyow
  class Loader
    # @api private
    class Context
      attr_reader :target, :path, :comments

      def initialize(target, code, path)
        @target, @path = target, path

        @comments, @uncommented_code = split_comments(code)
      end

      def load
        Thread.current[:__pw_loader_context] = self

        PakyowToplevel.load(@uncommented_code, @path, @comments.lines.count + 1)
      ensure
        Thread.current[:__pw_loader_context] = nil
      end

      private def indent(code)
        code.split("\n").map { |line| "  #{line}" }.join("\n")
      end

      private def split_comments(code)
        lines = code.lines

        if (line_number = first_nonblank_or_commented_line_number(lines))
          if lines.empty? || line_number == 1
            ["", code]
          else
            [lines[0...(line_number - 1)].join, lines[(line_number - 1)..].join]
          end
        else
          [lines.join, ""]
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
    end
  end
end
