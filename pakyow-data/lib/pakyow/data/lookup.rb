module Pakyow
  module Data
    class Lookup
      def initialize(models)
        @models = models
      end

      def method_missing(name)
        if model = @models[name]
          ModelProxy.new(model)
        else
          nil
        end
      end
    end
  end
end
