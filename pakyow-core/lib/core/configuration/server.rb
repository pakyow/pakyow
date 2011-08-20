module Pakyow
  module Configuration
    class Server
      class << self
        attr_accessor :port, :host
        
        # On what port does the application run?
        def port
          @port || 3000
        end
        
        # On what host does the application run?
        def host
          @host || '0.0.0.0'
        end
      end
    end
  end
end
