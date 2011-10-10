module Pakyow
  module Configuration
    autoload :Mailer, 'mailer/configuration/mailer'
    
    class Base
      def self.mailer
        Configuration::Mailer
      end
    end
  end
end
