# frozen_string_literal: true

require "pakyow/support/makeable"

module Pakyow
  class Loader
    def initialize(target, namespace, path)
      @target, @namespace, @path = target, namespace, path
    end

    def call(eval_binding = binding)
      eval(File.read(@path), eval_binding, @path)
    end

    def method_missing(name, *args, **kargs, &block)
      args[0] = Support::ClassName.new(@namespace, args[0]) if args[0].is_a?(Symbol)
      @target.public_send(name, *args, **kargs, &block)
    end
  end
end
