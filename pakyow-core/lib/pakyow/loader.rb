# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  # Evals the content of a file into a target.
  #
  class Loader
    extend Support::ClassState
    class_state :__loaded_paths, default: []

    attr_reader :path

    class << self
      def load_path(path, target:, pattern: "*.rb", reload: false)
        Dir.glob(File.join(path, pattern)).sort.each do |file_path|
          if reload || !@__loaded_paths.include?(file_path)
            Loader.new(file_path).call(target)
            @__loaded_paths << file_path
          end
        end

        Dir.glob(File.join(path, "*")).sort.select { |each_path|
          File.directory?(each_path)
        }.each do |directory_path|
          load_path(directory_path, target: target, pattern: pattern, reload: reload)
        end
      end

      def reset
        @__loaded_paths.clear
      end
    end

    def initialize(path)
      @path = path
    end

    def call(target)
      class_or_module = case target
      when Class, Module
        target
      else
        raise ArgumentError, "expected `#{target}' to be a class or module"
      end

      unless target.name
        raise ArgumentError, "cannot load `#{@path}' on unnamed target (`#{target}')"
      end

      comments, uncommented_code = split_comments(code)

      # While we could just class_eval the code onto the target, this will break if the code uses
      # a refinement. Building up the code like below provides the lexical scope needed for things
      # like refinements to work correctly.
      #
      code_to_load = case class_or_module
      when Class
        <<~CODE
          #{comments}class #{class_or_module}
          #{indent(uncommented_code.strip)}
          end
        CODE
      when Module
        <<~CODE
          #{comments}module #{class_or_module}
          #{indent(uncommented_code.strip)}
          end
        CODE
      end

      eval code_to_load, TOPLEVEL_BINDING, @path, 0
    end

    private def code
      File.read(@path)
    end

    private def indent(code)
      code.split("\n").map { |line| "  #{line}" }.join("\n")
    end

    private def split_comments(code)
      line_number = first_nonblank_or_commented_line_number(code)

      if line_number == 1
        return nil, code
      else
        lines = code.each_line.to_a

        return lines[0...(line_number - 1)].join, lines[(line_number - 1)..-1].join
      end
    end

    private def first_nonblank_or_commented_line_number(code)
      code.each_line.each_with_index do |line, index|
        line.strip!

        unless line.empty? || line[0] == "#"
          return index + 1
        end
      end

      nil
    end
  end
end
