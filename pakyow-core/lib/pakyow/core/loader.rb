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

    def method_missing(name, *args, &block)
      if args[0].is_a?(Symbol)
        args[0] = Support::ClassName.new(@namespace, args[0])
        @target.public_send(name, *args, &block)
      else
        @target.public_send(name, *args, namespace: @namespace, &block)
      end
    end
  end
end
