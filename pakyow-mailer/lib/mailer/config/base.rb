module Pakyow
  module Config
    autoload :Mailer, 'mailer/config/mailer'
    
    class Base
      def self.mailer
        Config::Mailer
      end
    end
  end
end
