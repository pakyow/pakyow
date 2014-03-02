module Pakyow
  module Config
    class Mailer
      Config::Base.register_config(:mailer, self)

      class << self
        attr_accessor :default_sender, :default_content_type, :delivery_method, :delivery_options, :encoding
        
        def default_sender
          @default_sender || "Pakyow"
        end
        
        def default_content_type
          @default_content_type || 'text/html; charset=' + encoding
        end
        
        def delivery_method
          @delivery_method || :sendmail
        end
        
        def delivery_options
          @delivery_options || {:enable_starttls_auto => false}
        end

        def encoding
          @encoding || 'UTF-8'
        end
      end
    end
  end
end
