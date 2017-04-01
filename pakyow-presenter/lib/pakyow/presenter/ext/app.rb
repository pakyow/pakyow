module Pakyow
  class App
    class << self
      RESOURCE_ACTIONS[:presenter] = proc do |app, name, _, _|
        app.bindings(name) { scope(name) { restful(name) } }
      end

      # TODO: definable
      def bindings(set_name = :main, &block)
        if set_name && block
          bindings[set_name] = block
        else
          @bindings ||= {}
        end
      end

      # TODO: definable
      def processor(*args, &block)
        args.each {|format|
          processors[format] = block
        }
      end

      # TODO: definable
      def processors
        @processors ||= {}
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    # TODO: definable
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end

    def processors
      self.class.processors
    end

    # TODO: do we need this?
    def presenter
      @presenter
    end
  end
end
