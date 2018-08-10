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
      target.__class_name.namespace.parts.each do |part|
        code << "module #{Support.inflector.camelize(part)}\n"
      end

      code << "class #{Support.inflector.camelize(target.__class_name.name)}\n"
      code << File.read(@path)
      code << "end\n"

      target.__class_name.namespace.parts.count.times do
        code << "end\n"
      end

      eval(code, TOPLEVEL_BINDING, @path, 1 - target.__class_name.namespace.parts.count - 1)
    end
  end
end
