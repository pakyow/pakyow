# frozen_string_literal: true

require "mini_racer"

require "pakyow/support/inflector"

module Pakyow
  module Assets
    # Provides a Ruby API to a Javascript.
    #
    class Script
      class << self
        # Registers a dependency at `path`.
        #
        def dependency(path)
          (dependencies << path).uniq!
        end

        # Defines a Javascript function callable by `name`.
        #
        def function(name, code)
          functions[name] = code
        end

        def method_missing(name, *args)
          if functions.include?(name)
            context.call(name.to_s, *args)
          else
            super
          end
        end

        def respond_to_missing?(name, *)
          functions.include?(name) || super
        end

        # Destroy the internal context.
        #
        def destroy
          @__context = nil
        end

        private def dependencies
          @__dependencies ||= []
        end

        private def functions
          @__functions ||= {}
        end

        private def context
          @__context ||= load_context(MiniRacer::Context.new)
        end

        private def load_context(context)
          load_dependencies(context)
          load_functions(context)
          context
        end

        private def load_dependencies(context)
          dependencies.each do |dependency|
            context.eval(File.read(dependency))
          end
        end

        private def load_functions(context)
          functions.each_value do |function|
            context.eval(function)
          end
        end
      end
    end
  end
end
