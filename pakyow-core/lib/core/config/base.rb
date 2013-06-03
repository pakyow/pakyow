module Pakyow
  module Config
    autoload :App, 'core/config/app'
    autoload :Server, 'core/config/server'
    autoload :Cookies, 'core/config/cookies'
    
    class Base
      # Fetches the server config    
      def self.server
        Config::Server
      end
      
      # Fetches the application config
      def self.app
        Config::App
      end

      # Fetches the cookies config
      def self.cookies
        Config::Cookies
      end
      
      # Resets all config
      def self.reset!
        %w[app server].each do |type|
          klass = self.send(type.to_sym)
          klass.instance_variables.each do |var|
            # Assumes path shouldn't be reset, since it's only set
            # once when Pakyow::Application is inherited.
            next if var.to_sym == :'@path'
            klass.send("#{var.to_s.gsub('@', '')}=", nil)
          end
        end
      end
    end
  end
end
