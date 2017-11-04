module Pakyow
  class Loader
    def initialize(target, name, path)
      @target, @name, @path = target, name.to_sym, path
    end

    def call(eval_binding = binding)
      eval(File.read(@path), eval_binding)
    end

    def method_missing(name, *args, &block)
      args.unshift(@name) unless args[0].is_a?(Symbol)
      @target.public_send(name, *args, &block)
    end
  end
end
