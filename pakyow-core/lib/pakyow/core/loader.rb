# frozen_string_literal: true

module Pakyow
  class Loader
    def initialize(target, prefix, path)
      @target, @prefix, @path = target, prefix.to_sym, path
    end

    def call(eval_binding = binding)
      eval(File.read(@path), eval_binding, @path)
    end

    def method_missing(name, *args, **kargs, &block)
      args[0] = ConcernName.new(@prefix, args[0]) if args[0].is_a?(Symbol)
      @target.public_send(name, *args, **kargs, &block)
    end
  end
end
