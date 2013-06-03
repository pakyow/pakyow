module Pakyow
  class App
    class << self
      @@bindings = {}
      
      def bindings(set_name = :main, &block)
        if set_name && block
          @@bindings[set_name] = block
        else
          @@bindings
        end
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end
  end
end
