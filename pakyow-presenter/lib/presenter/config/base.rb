module Pakyow
  module Config
    autoload :Presenter, 'presenter/config/presenter'
    
    class Base
      # Fetches the server configuration    
      def self.presenter
        Config::Presenter
      end
    end
  end
end
