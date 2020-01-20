# frozen_string_literal: true

module Pakyow
  # Evals the content of a file into a target.
  #
  class Loader
    attr_reader :path

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

      # While we could just class_eval the code onto the target, this will break if the code uses
      # a refinement. Building up the code like below provides the lexical scope needed for things
      # like refinements to work correctly.
      #
      code_to_load = case class_or_module
      when Class
        <<~CODE
          class #{class_or_module}
          #{indent(code.strip)}
          end
        CODE
      when Module
        <<~CODE
          module #{class_or_module}
          #{indent(code.strip)}
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
  end
end
