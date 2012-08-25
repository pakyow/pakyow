module Pakyow
  module Configuration
    class Server
      class << self
        attr_accessor :port, :host, :handler
        
        # On what port does the application run?
        def port
          @port || 3000
        end
        
        # On what host does the application run?
        def host
          @host || '0.0.0.0'
        end
        
        # If set, adds a handler to try (e.g. puma)
        def handler
          @handler || nil
        end
      end
    end
  end
end
