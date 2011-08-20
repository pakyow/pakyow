module Pakyow
  module Configuration
    autoload :Presenter, 'presenter/configuration/presenter'
    
    class Base
      # Fetches the server configuration    
      def self.presenter
        Configuration::Presenter
      end
    end
  end
end
