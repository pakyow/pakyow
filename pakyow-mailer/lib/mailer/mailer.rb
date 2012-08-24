module Pakyow
  class Mailer
    attr_accessor :view, :message
  
    def initialize(view_path)
      @view = Pakyow.app.presenter.view_for_full_view_path(view_path, true)
      
      @message               = Mail.new
      @message.from          = Configuration::Base.mailer.default_sender
      @message.content_type  = Configuration::Base.mailer.default_content_type
      @message.delivery_method(Configuration::Base.mailer.delivery_method, Configuration::Base.mailer.delivery_options)
    end
    
    def deliver_to(recipient, subject = nil)
      html_content = self.view.to_html
      @message.html_part do
        content_type 'text/html; charset=UTF-8'
        body html_content
      end
      
      @message.subject = subject if subject
      
      if recipient.is_a?(Array)
        recipient.each {|r| deliver(r)}
      else
        deliver(recipient)
      end
    end
    
    protected
    
    def deliver(recipient)
      @message.to = recipient
      @message.deliver
    end
  end
end
