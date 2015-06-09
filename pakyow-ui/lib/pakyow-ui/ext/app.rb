module Pakyow
  class App
    attr_reader :ui

    #TODO I'd like this abstracted out into a registry type model
    # in pakyow-core; there's a ton of repitition currently
    class << self
      def mutators(scope = nil, &block)
        @mutators ||= {}

        if scope && block
          @mutators[scope] = block
        else
          @mutators || {}
        end
      end

      def mutable(scope, &block)
        @mutables ||= {}
        @mutables[scope] = block
      end

      def mutables
        @mutables || {}
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    def mutators(scope = nil, &block)
      self.class.mutators(scope, &block)
    end

    def mutable(scope, &block)
      self.class.mutable(scope, &block)
    end

    def mutables
      self.class.mutables
    end
  end
end
