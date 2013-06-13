module Pakyow
  class App
    class << self
      @@bindings = {}
      @@processors = {}
      
      def bindings(set_name = :main, &block)
        if set_name && block
          @@bindings[set_name] = block
        else
          @@bindings
        end
      end

      def processor(format, &block)
        @@processors[format] = block
      end

      def processors
        @@processors
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end
  end
end
