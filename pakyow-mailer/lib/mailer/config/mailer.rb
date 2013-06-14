module Pakyow
  module Config
    class Mailer
      Config::Base.register_config(:mailer, self)

      class << self
        attr_accessor :default_sender, :default_content_type, :delivery_method, :delivery_options
        
        def default_sender
          @default_sender || "Pakyow"
        end
        
        def default_content_type
          @default_content_type || 'text/html; charset=UTF-8'
        end
        
        def delivery_method
          @delivery_method || :sendmail
        end
        
        def delivery_options
          @delivery_options || {:enable_starttls_auto => false}
        end
      end
    end
  end
end
