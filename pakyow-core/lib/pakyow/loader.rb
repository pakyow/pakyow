# frozen_string_literal: true

require "pakyow/support/inflector"
require "pakyow/support/makeable"

module Pakyow
  # Loads files that define an app aspect and names the objects appropriately.
  #
  class Loader
    def initialize(path)
      @path = path
    end

    def call(target)
      code = String.new
      target.object_name.namespace.parts.each do |part|
        code << "module #{Support.inflector.camelize(part)}\n"
      end

      code << "class #{Support.inflector.camelize(target.object_name.name)}\n"
      code << File.read(@path)
      code << "end\n"

      target.object_name.namespace.parts.count.times do
        code << "end\n"
      end

      object = eval(code, TOPLEVEL_BINDING, @path, 1 - target.object_name.namespace.parts.count - 1)

      if object.respond_to?(:__source_location)
        object.__source_location = [@path, 1]
      end

      object
    end
  end
end
