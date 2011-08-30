module Pakyow
  module Configuration
    autoload :App, 'core/configuration/app'
    autoload :Server, 'core/configuration/server'    
    
    class Base
      # Fetches the server configuration    
      def self.server
        Configuration::Server
      end
      
      # Fetches to application configuration
      def self.app
        Configuration::App
      end
      
      # Resets all configuration
      def self.reset!
        %w[app server].each do |type|
          klass = self.send(type.to_sym)
          klass.instance_variables.each do |var|
            # Assumes application_path shouldn't be reset, since it's only set
            # once when Pakyow::Application is inherited.
            next if var.to_sym == :'@application_path'
            klass.send("#{var.to_s.gsub('@', '')}=", nil)
          end
        end
      end
    end
  end
end
