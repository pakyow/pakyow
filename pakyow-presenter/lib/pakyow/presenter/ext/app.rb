module Pakyow
  class App
    class << self
      RESOURCE_ACTIONS[:presenter] = Proc.new { |app, set_name, _, _|
        app.bindings(set_name) { scope(set_name) { restful(set_name) } }
      }

      def bindings(set_name = :main, &block)
        if set_name && block
          bindings[set_name] = block
        else
          @bindings ||= {}
        end
      end

      def processor(*args, &block)
        args.each {|format|
          processors[format] = block
        }
      end

      def processors
        @processors ||= {}
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end
  end
end
