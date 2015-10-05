module Pakyow
  class App
    class << self
      # Defines mutators for a scope.
      #
      # @api public
      def mutators(scope = nil, &block)
        @mutators ||= {}

        if scope && block
          @mutators[scope] = block
        else
          @mutators || {}
        end
      end

      # Defines a mutable object.
      #
      # @api public
      def mutable(scope, &block)
        @mutables ||= {}
        @mutables[scope] = block
      end

      # @api private
      def mutables
        @mutables || {}
      end
    end

    # Convenience method for defining mutators on an app instance.
    #
    # @api public
    def mutators(scope = nil, &block)
      self.class.mutators(scope, &block)
    end

    # Convenience method for defining a mutable on an app instance.
    #
    # @api public
    def mutable(scope, &block)
      self.class.mutable(scope, &block)
    end

    # @api private
    def mutables
      self.class.mutables
    end
  end
end
